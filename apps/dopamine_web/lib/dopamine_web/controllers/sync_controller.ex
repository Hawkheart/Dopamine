defmodule DopamineWeb.SyncController do
  use DopamineWeb, :controller

  defmodule Arguments do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:filter, :string)
      field(:since, :integer)
      field(:full_state, :boolean, default: false)
      field(:set_presence, :string, default: "online")
      field(:timeout, :integer, default: 0)
    end

    def changeset(data, attrs) do
      data
      |> cast(attrs, [:filter, :since, :full_state, :set_presence, :timeout])
      |> validate_inclusion(:set_presence, ["online", "offline", "unavailable"])
    end
  end

  def sync(conn, params) do
    changeset = Arguments.changeset(%Arguments{}, params)

    if changeset.valid? do
      args = Ecto.Changeset.apply_changes(changeset)

      if not is_nil(args.filter) do
        import Ecto.Query, only: [from: 2]

        filter =
          Dopamine.Repo.one!(from(f in Dopamine.Filters.Filter, where: f.id == ^args.filter))

        IO.inspect(filter)
      end

      IO.inspect(args)

      results =
        conn
        |> update_presence(args.set_presence)
        |> do_sync(args)
        |> put_now()

      conn |> json(results)
    else
      # TODO - error this better
      {:error, :invalid}
    end
  end

  defp update_presence(conn, "offline") do
    # by the standard, NOP in this case.
    conn
  end

  defp update_presence(conn, status) do
    # Otherwise, does nothing.
    user = conn.assigns.session.user
    Dopamine.Accounts.set_presence(user, {status, ""})
    conn
  end

  defp do_sync(conn, %Arguments{since: since}) when is_nil(since) do
    # Initial sync.

    import Ecto.Query, only: [from: 2]

    user = Dopamine.Repo.preload(conn.assigns.user, [:memberships, memberships: [:room]])

    joined_rooms =
      Enum.filter(user.memberships, fn membership -> membership.status == "joined" end)
      |> Enum.map(fn membership -> membership.room end)
      |> Enum.map(fn room -> {room.matrix_id, calculate_timeline(room)} end)
      |> Enum.into(%{})

    IO.puts("joined_rooms data")
    IO.inspect(joined_rooms)

    query =
      from(d in Dopamine.Accounts.Data,
        where: d.user_id == ^conn.assigns.user.id and is_nil(d.room_id)
      )

    records = Dopamine.Repo.all(query)

    account_data =
      for record <- records,
          is_nil(record.room_id),
          into: [],
          do: %{type: record.type, content: record.content}

    IO.puts("account data received")
    IO.inspect(account_data)

    %{account_data: %{events: account_data}, rooms: %{join: joined_rooms}}
  end

  defp do_sync(conn, %Arguments{timeout: timeout, since: since}) do
    import Ecto.Query, only: [from: 2]

    user = conn.assigns.user |> Dopamine.Repo.preload([:memberships])

    timestamp = DateTime.from_unix!(since)

    query =
      from(d in Dopamine.Accounts.Data,
        where:
          d.user_id == ^conn.assigns.user.id and is_nil(d.room_id) and d.updated_at > ^timestamp
      )

    new_data = Dopamine.Repo.all(query)

    rooms =
      user.memberships
      |> Enum.filter(fn x -> x.status == "joined" end)
      |> Enum.map(fn x -> x.room_id end)

    query =
      from(e in Dopamine.Rooms.Event,
        where: e.room_id in ^rooms and e.updated_at > ^timestamp,
        order_by: [e.depth, e.updated_at]
      )

    new_events =
      Dopamine.Repo.all(query)
      |> Dopamine.Repo.preload([:room])
      |> Enum.group_by(fn x -> x.room.matrix_id end)

    if Enum.empty?(new_data) and Enum.empty?(new_events) do
      # Long poll for new events.

      :ok =
        Phoenix.PubSub.subscribe(
          DopamineWeb.PubSub,
          Dopamine.Accounts.User.matrix_id(conn.assigns.user)
        )

      received =
        receive do
          {:account_data, data} ->
            %{account_data: %{events: [%{type: data.type, content: data.content}]}}

          {:join_room, room} ->
            %{rooms: %{join: %{room.matrix_id => calculate_timeline(room)}}}

          {:event, room, event} ->
            %{
              rooms: %{join: %{room.matrix_id => %{timeline: %{events: [format_event(event)]}}}}
            }
        after
          timeout -> %{}
        end

      IO.puts("What did we get?")
      IO.inspect(received)

      received
    else
      account_data =
        for record <- new_data,
            is_nil(record.room_id),
            into: [],
            do: %{type: record.type, content: record.content}

      joined_rooms =
        for {room_id, events} <- new_events, into: %{} do
          timeline = Enum.map(events, &format_event/1)
          {room_id, %{timeline: %{events: timeline}}}
        end

      %{account_data: %{events: account_data}, rooms: %{join: joined_rooms}}
    end
  end

  defp put_now(result) do
    now = DateTime.utc_now() |> DateTime.to_unix(:second) |> to_string()

    Map.put(result, :next_batch, now)
  end

  defp calculate_timeline(room) do
    {:ok, room} = Dopamine.Rooms.get_room(room.matrix_id)

    events =
      GenServer.call(room, :all_events)
      |> Enum.map(fn e -> format_event(e) end)

    IO.inspect(events)

    %{timeline: %{events: events}}
  end

  defp format_event(event) do
    IO.inspect(event)

    event =
      event
      |> Map.from_struct()
      |> Map.drop([
        :__meta__,
        :prev_content,
        :room,
        :depth,
        :id,
        :inserted_at,
        :room_id,
        :updated_at
      ])
      |> Map.put(:event_id, event.matrix_id)
      |> Map.put(:origin_server_ts, event.origin_timestamp |> DateTime.to_unix(:millisecond))
      |> Map.drop([:matrix_id, :origin_timestamp])

    if is_nil(event.state_key), do: Map.delete(event, :state_key), else: event
  end
end
