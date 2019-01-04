defmodule Dopamine.Rooms do
  import Ecto.Query, only: [from: 2]

  def get_current_state(room_id, type, state_key) do
    query =
      from(e in Dopamine.Rooms.Event,
        where: e.room_id == ^room_id and e.type == ^type and e.state_key == ^state_key,
        order_by: [asc: e.depth],
        limit: 1
      )

    Dopamine.Repo.one(query)
  end

  def create_room(user, args) do
    alias Dopamine.Rooms.Room
    alias Dopamine.Rooms.Event
    alias Ecto.Multi

    matrix_id = :crypto.strong_rand_bytes(16) |> Base.encode16()

    room = Dopamine.Repo.insert!(%Room{id: 0})
    room_id = room.id

    events = [
      %{
        content: %{},
        unsigned: %{},
        depth: 0,
        origin_timestamp: 0,
        sender: "@root@localhost",
        state_key: "omnomnomnom",
        type: "aaaa",
        room_id: room_id
      },
      %{
        content: %{"something" => "else"},
        unsigned: %{},
        depth: 1,
        origin_timestamp: 0,
        sender: "@root@localhost",
        state_key: "omnomnomnom",
        type: "aaaa",
        room_id: room_id
      }
    ]

    events
    |> Enum.map(fn e -> Event.changeset(%Event{}, e) end)
    |> Enum.each(fn e -> Dopamine.Repo.insert!(e) end)

    IO.inspect(room_id)
  end

  def public_rooms() do
    query = from(r in Dopamine.Rooms.Room, where: r.public == true)
    Dopamine.Repo.all(query)
  end
end
