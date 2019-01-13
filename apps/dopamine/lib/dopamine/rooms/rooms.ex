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
    with {:ok, _pid} <- Dopamine.MatrixRegistry.lookup(matrix_id) do
      {:ok, Dopamine.MatrixRegistry.name(matrix_id)}
    else
      err ->
        IO.inspect(err)
        {:error, :no_such_room}
    end
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
    public = args.visibility == "public"

    user_mxid = Dopamine.Accounts.User.matrix_id(user)

    {:ok, room} = create_empty_room(user_mxid, public)

    {:ok, room_pid} = get_room(room.matrix_id)

    preset = get_preset(args)
    # initial events...
    events = [
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
        type: "m.room.power_levels"
      },
      %{
        content: %{"join_rule" => join_rules(preset)},
        unsigned: %{},
        sender: user_mxid,
        type: "m.room.join_rules",
        state_key: ""
      },
      %{
        content: %{"history_visibility" => history_visibility(preset)},
        unsigned: %{},
        sender: user_mxid,
        state_key: "",
        type: "m.room.history_visibility"
      },
      %{
        content: %{"guest_access" => guest_access(preset)},
        unsigned: %{},
        sender: user_mxid,
        state_key: "",
        type: "m.room.guest_access"
      },
      %{
        content: %{"membership" => "join"},
        unsigned: %{},
        state_key: user_mxid,
        sender: user_mxid,
        type: "m.room.member"
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
            sender: user_mxid,
            state_key: "",
            type: "m.room.name",
            content: %{name: args.name}
          }
          | events
        ],
        else: events

    events = Enum.reverse(events)

    events |> Enum.each(fn event -> Dopamine.Rooms.Server.insert_event!(room_pid, event) end)

    membership = %{
      room_id: room.id,
      user_id: user.id,
      status: "joined"
    }

    membership = Dopamine.Rooms.Membership.changeset(%Dopamine.Rooms.Membership{}, membership)

    Dopamine.Repo.insert!(membership)

    IO.puts("new membership???")
    IO.inspect(membership)

    Phoenix.PubSub.broadcast(
      DopamineWeb.PubSub,
      user_mxid,
      {:join_room, room}
    )

    {:ok, room.matrix_id}
  end

  defp create_empty_room(creator, public, version \\ "1") do
    root_event_content = %{creator: creator, "m.federate": false, room_version: version}
    root_event_id = Dopamine.MatrixID.generate(:event)

    initial_state = %{
      "m.room.create" => %{"" => %{content: root_event_content, current_id: root_event_id}}
    }

    room =
      Dopamine.Rooms.Room.creation_changeset(%Dopamine.Rooms.Room{}, %{
        public: public,
        state: initial_state
      })
      |> Dopamine.Repo.insert!()

    attrs = %{
      room_id: room.id,
      matrix_id: root_event_id,
      content: root_event_content,
      unsigned: %{},
      type: "m.room.create",
      state_key: "",
      depth: 0
    }

    %Dopamine.Rooms.Event{}
    |> Dopamine.Rooms.Event.creation_changeset(attrs)
    |> Dopamine.Repo.insert!()

    {:ok, room}
  end

  def public_rooms() do
    query = from(r in Dopamine.Rooms.Room, where: r.public == true)
    Dopamine.Repo.all(query)
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
