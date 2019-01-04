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

    %{account_data: %{events: account_data}}
  end

  defp do_sync(conn, %Arguments{timeout: timeout, since: since}) do
    import Ecto.Query, only: [from: 2]

    timestamp = DateTime.from_unix!(since)

    query =
      from(d in Dopamine.Accounts.Data,
        where:
          d.user_id == ^conn.assigns.user.id and is_nil(d.room_id) and d.updated_at > ^timestamp
      )

    new_data = Dopamine.Repo.all(query)

    IO.inspect(new_data)

    if Enum.empty?(new_data) do
      # Long poll for new events.
      Dopamine.PubSub.subscribe_to_user(conn.assigns.user.username)

      received =
        receive do
          {:account_data, data} ->
            %{account_data: %{events: [%{type: data.type, content: data.content}]}}
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

      %{account_data: %{events: account_data}}
    end
  end

  defp put_now(result) do
    now = DateTime.utc_now() |> DateTime.to_unix(:second) |> to_string()

    Map.put(result, :next_batch, now)
  end
end
