defmodule Dopamine.Rooms.Server do
  use GenServer, restart: :transient

  defstruct room: nil, depth: 0

  def start_link(args) do
    room_id = Keyword.get(args, :room_id)
    GenServer.start_link(__MODULE__, room_id, args)
  end

  def insert_event!(room, event) do
    GenServer.call(room, {:new_event, event})
  end

  def get_state(room, type, state_key \\ "", default \\ nil) do
    GenServer.call(room, {:get_state, type, state_key, default})
  end

  # 30 minutes (in milliseconds)
  @timeout 1000 * 60 * 30

  # 30 seconds (for testing)
  @timeout 1000 * 30
  def init(room_id) do
    room =
      Dopamine.Repo.get(Dopamine.Rooms.Room, room_id)
      |> Dopamine.Repo.preload([:memberships, events: all_events_query(), memberships: [:user]])

    IO.puts("Room server for room '#{room.matrix_id}' coming online.")
    IO.inspect(room.matrix_id)
    IO.puts("Room state:")
    IO.inspect(room.state)
    IO.inspect(room)

    max_depth = hd(room.events).depth

    Registry.register(Dopamine.MatrixRegistry, room.matrix_id, self())

    state = %__MODULE__{room: room, depth: max_depth}
    {:ok, state, @timeout}
  end

  def handle_call(:get_visibility, _sender, state) do
    {:reply, state.room.public, state, @timeout}
  end

  def handle_call(
        {:new_event, event},
        _sender,
        state
      ) do
    event = Map.put(event, :depth, state.depth + 1)
    event = Map.put(event, :room_id, state.room.id)

    state = %__MODULE__{state | depth: state.depth + 1}

    event =
      Dopamine.Rooms.Event.creation_changeset(%Dopamine.Rooms.Event{}, event)
      |> Dopamine.Repo.insert!()

    room = %Dopamine.Rooms.Room{state.room | events: [event | state.room.events]}
    state = %__MODULE__{state | room: room}

    state =
      if Dopamine.Rooms.Event.state_event?(event) do
        current_state = get_current_state(state, event.type, event.state_key)

        prev_id =
          if not is_nil(current_state) do
            current_state["current_id"]
          else
            nil
          end

        content = event.content
        current_id = event.matrix_id

        new_state =
          Map.merge(state.room.state, %{
            event.type => %{
              event.state_key => %{
                "content" => content,
                "prev_id" => prev_id,
                "current_id" => current_id
              }
            }
          })

        IO.puts("adding a state event...")

        changeset = Dopamine.Rooms.Room.changeset(room, %{state: new_state})

        Dopamine.Repo.update!(changeset)

        put_in(state.room.state, new_state)
      else
        state
      end

    # Handle any side-effects...
    state = state |> handle_event(event)

    # Broadcast the event to all current members.
    Enum.each(state.room.memberships, fn membership ->
      user_id = Dopamine.Accounts.User.matrix_id(membership.user)
      Phoenix.PubSub.broadcast!(DopamineWeb.PubSub, user_id, {:event, state.room, event})
    end)

    {:reply, {:ok, event}, state, @timeout}
  end

  def handle_call({:set_visibility, public}, _sender, state) do
    changeset =
      state.room
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_change(:public, public)

    room = Dopamine.Repo.update!(changeset)
    state = put_in(state.room, room)

    {:reply, :ok, state, @timeout}
  end

  def handle_call({:get_state, type, state_key, default}, _sender, state) do
    current_state = get_current_state(state, type, state_key)

    content =
      if not is_nil(current_state) do
        current_state["content"]
      else
        default
      end

    IO.inspect(content)

    {:reply, {:ok, content}, state, @timeout}
  end

  def handle_call(:all_events, _sender, state) do
    IO.inspect(state.room)

    events = state.room.events |> Enum.reverse()
    {:reply, events, state, @timeout}
  end

  def handle_info(:timeout, state) do
    IO.puts("Room server shutting down, timed out...")
    {:stop, {:shutdown, "Server timed out."}, state}
  end

  defp get_current_state(state, type, state_key) do
    state_of_type = Map.get(state.room.state, type, nil)

    if not is_nil(state_of_type) do
      Map.get(state_of_type, state_key)
    end
  end

  defp all_events_query() do
    import Ecto.Query, only: [from: 2]

    from(e in Dopamine.Rooms.Event, order_by: [desc: e.depth, desc: e.inserted_at])
  end

  defp handle_event(state, event = %Dopamine.Rooms.Event{type: "m.room.member"}) do
    # TODO this will need to be redone when federation support comes.
    # Will need to separate local/remote users.

    IO.puts("Handling new membership.")

    username = Dopamine.MatrixID.parse(event.state_key).localpart

    user = Dopamine.Accounts.get(username)

    membership = %{
      room_id: state.room.id,
      user_id: user.id,
      status: "joined"
    }

    membership = Dopamine.Rooms.Membership.changeset(%Dopamine.Rooms.Membership{}, membership)

    membership = Dopamine.Repo.insert!(membership) |> Dopamine.Repo.preload(:user)

    IO.inspect(membership)
    IO.inspect(state.room.memberships)

    room = %Dopamine.Rooms.Room{state.room | memberships: [membership | state.room.memberships]}

    Phoenix.PubSub.broadcast!(
      DopamineWeb.PubSub,
      Dopamine.Accounts.User.matrix_id(user),
      {:join_room, room}
    )

    %__MODULE__{state | room: room}
  end

  defp handle_event(state, _event) do
    state
  end
end
