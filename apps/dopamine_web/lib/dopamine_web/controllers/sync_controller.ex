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
        |> put_now(args.since)

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
    # This version called on an initial sync (since argument was not provided.)

    import Ecto.Query, only: [from: 2]

    # Preload all of this user's memberships (and the attached rooms) so we can properly sync.
    user = Dopamine.Repo.preload(conn.assigns.user, [:memberships, memberships: [:room]])

    # Find the list of joined rooms (where the membership status is currently "joined")
    # Then, calculate the timeline.
    joined_rooms =
      Enum.filter(user.memberships, fn membership -> membership.status == "joined" end)
      |> Enum.map(fn membership -> membership.room end)
      |> Enum.map(fn room -> {room.matrix_id, calculate_timeline(room)} end)
      |> Enum.into(%{})

    IO.puts("joined_rooms data")
    IO.inspect(joined_rooms)

    # Query all of the current user's global account data.
    query =
      from(d in Dopamine.Accounts.Data,
        where: d.user_id == ^conn.assigns.user.id and is_nil(d.room_id)
      )

    records = Dopamine.Repo.all(query)

    # Format the account data for the client.
    account_data =
      for record <- records,
          is_nil(record.room_id),
          into: [],
          do: %{type: record.type, content: record.content}

    IO.puts("account data received")
    IO.inspect(account_data)

    # Return the sync data to the client.
    %{account_data: %{events: account_data}, rooms: %{join: joined_rooms}}
  end

  defp do_sync(conn, %Arguments{timeout: timeout, since: since}) do
    # This version is called when we are listening for new events.

    import Ecto.Query, only: [from: 2]

    # Load all of the user's memberships.
    user = conn.assigns.user |> Dopamine.Repo.preload([:memberships])

    timestamp = DateTime.from_unix!(since)

    # See if the user has updated their global account data since the last sync.
    query =
      from(d in Dopamine.Accounts.Data,
        where:
          d.user_id == ^conn.assigns.user.id and is_nil(d.room_id) and d.updated_at > ^timestamp
      )

    new_data = Dopamine.Repo.all(query)

    # Get the list of rooms this user belondgs to.
    rooms =
      user.memberships
      |> Enum.filter(fn x -> x.status == "joined" end)
      |> Enum.map(fn x -> x.room_id end)

    # Find any events that were changed since the last sync.
    query =
      from(e in Dopamine.Rooms.Event,
        where: e.room_id in ^rooms and e.updated_at > ^timestamp,
        order_by: [e.depth, e.updated_at]
      )

    # Sort them into lists based off of the room they belong to.
    new_events =
      Dopamine.Repo.all(query)
      |> Dopamine.Repo.preload([:room])
      |> Enum.group_by(fn x -> x.room.matrix_id end)

    if Enum.empty?(new_data) and Enum.empty?(new_events) do
      # If there's nothing, wait for new events to come in.

      # Subscribe to the PubSub channel for this user.
      :ok =
        Phoenix.PubSub.subscribe(
          DopamineWeb.PubSub,
          Dopamine.Accounts.User.matrix_id(conn.assigns.user)
        )

      # Now we wait...
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
          # If we time out without receiving anything, nothing happened.
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
          # TODO -> properly format this (limited, prev_batch)
          {room_id, %{timeline: %{events: timeline}}}
        end

      %{account_data: %{events: account_data}, rooms: %{join: joined_rooms}}
    end
  end

  defp put_now(result, since) do
    since = if is_nil(since), do: 0, else: since

    # TODO this is really bad.
    # We need to be using tokens that match the last-received event.
    # But, for now, we're only able to do this on messages in rooms...

    last_room =
      if(Map.get(result, :rooms)) do
        IO.inspect(result.rooms.join)

        result.rooms.join
        |> Enum.map(fn {_matrix_id, room} -> room.timeline.events end)
        |> Enum.map(fn timeline -> List.last(timeline) end)
        |> Enum.map(fn event -> event.origin_server_ts end)
        |> Enum.map(fn ts -> div(ts, 1000) end)
        |> Enum.max(fn -> 0 end)
      else
        0
      end

    next_batch = Enum.max([since, last_room])

    Map.put(result, :next_batch, next_batch)
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
