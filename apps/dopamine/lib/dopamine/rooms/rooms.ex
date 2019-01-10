defmodule Dopamine.Rooms do
  import Ecto.Query, only: [from: 2]

  def get_room(matrix_id) when is_binary(matrix_id) do
    with {:ok, matrix_id} <- Dopamine.MatrixID.cast(matrix_id) do
      get_room(matrix_id)
    else
      error -> error
    end
  end

  def get_room(matrix_id = %Dopamine.MatrixID{sigil: "!"}) do
    Dopamine.MatrixRegistry.lookup(matrix_id)
  end

  def get_room(%Dopamine.MatrixID{}) do
    {:error, :invalid}
  end

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
    alias Dopamine.Rooms.Membership
    alias Ecto.Multi

    public = args.visibility == "public"

    matrix_id = Dopamine.MatrixID.generate(:room)

    user_mxid = Dopamine.Accounts.User.matrix_id(user)

    preset = get_preset(args)

    events = [
      %{
        content: %{creator: user_mxid, "m.federate": false, room_version: "1"},
        unsigned: %{},
        sender: user_mxid,
        state_key: "",
        type: "m.room.create",
        depth: 0
      },
      %{
        content:
          Map.merge(
            %{
              "users" => %{user_mxid => 50}
            },
            args.power_level_content_override
          ),
        unsigned: %{},
        sender: user_mxid,
        state_key: "",
        type: "m.room.power_levels",
        depth: 1
      },
      %{
        content: %{"join_rule" => join_rules(preset)},
        unsigned: %{},
        sender: user_mxid,
        type: "m.room.join_rules",
        state_key: "",
        depth: 2
      },
      %{
        content: %{"history_visibility" => history_visibility(preset)},
        unsigned: %{},
        sender: user_mxid,
        state_key: "",
        type: "m.room.history_visibility",
        depth: 3
      },
      %{
        content: %{"guest_access" => guest_access(preset)},
        unsigned: %{},
        sender: user_mxid,
        state_key: "",
        type: "m.room.guest_access",
        depth: 4
      },
      %{
        content: %{"membership" => "join"},
        unsigned: %{},
        state_key: user_mxid,
        sender: user_mxid,
        type: "m.room.member",
        depth: 5
      }
    ]

    events = Enum.reverse(events)

    events =
      Enum.reduce(args.initial_state, events, fn event, acc = [head | _] ->
        event = Map.merge(%{"content" => %{}, "state_key" => "", "type" => ""}, event)

        [
          Map.merge(event, %{"sender" => user_mxid, "depth" => head.depth + 1, "unsigned" => %{}})
          | acc
        ]
      end)

    events =
      if not is_nil(args.name),
        do: [
          %{
            unsigned: %{},
            depth: hd(events).depth + 1,
            sender: user_mxid,
            state_key: "",
            type: "m.room.name",
            content: %{name: args.name}
          }
          | events
        ],
        else: events

    events = Enum.reverse(events)

    state = calculate_initial_state(events)

    room = %Room{matrix_id: matrix_id, public: public, state: state}

    multi =
      Multi.new()
      |> Multi.insert(:room, room)
      |> Multi.run(:membership, fn repo, %{room: room} ->
        repo.insert(%Membership{status: "joined", room_id: room.id, user_id: user.id})
      end)
      |> Multi.run(:events, fn repo, %{room: room} -> insert_events(repo, room, events) end)

    Dopamine.Repo.transaction(multi)
  end

  defp calculate_initial_state(events) do
    Enum.reduce(events, %{}, fn event, acc ->
      if Map.has_key?(event, "state_key") do
      else
        key = Jason.encode!(%{"state_key" => event.state_key, "type" => event.type})
        content = %Dopamine.Rooms.RoomState{content: event.content}
        Map.put(acc, key, content)
      end
    end)
  end

  def public_rooms() do
    query = from(r in Dopamine.Rooms.Room, where: r.public == true)
    Dopamine.Repo.all(query)
  end

  defp insert_events(repo, room, events) do
    alias Dopamine.Rooms.Event

    events =
      events
      |> Enum.map(fn e -> Map.put(e, :room_id, room.id) end)
      |> Enum.map(fn e -> Event.creation_changeset(%Event{}, e) end)

    results =
      events
      |> Enum.map(fn e -> repo.insert(e) end)
      |> Enum.reduce_while({:ok, []}, fn r, {:ok, events} ->
        case r do
          {:ok, event} -> {:cont, {:ok, [event | events]}}
          error -> {:halt, error}
        end
      end)

    results
  end

  defp join_rules("public_chat") do
    "public"
  end

  defp join_rules(_) do
    "invite"
  end

  defp history_visibility(_) do
    "shared"
  end

  defp guest_access("public_chat") do
    "forbidden"
  end

  defp guest_access(_) do
    "can_join"
  end

  defp get_preset(args) do
    if is_nil(args.preset) do
      "#{args.visibility}_chat"
    else
      args.preset
    end
  end
end
