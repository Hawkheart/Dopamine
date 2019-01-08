defmodule Dopamine.Rooms.Server do
  use GenServer, restart: :transient

  defstruct room: nil

  def start_link(args) do
    room_id = Keyword.get(args, :room_id)
    GenServer.start_link(__MODULE__, room_id, args)
  end

  # 30 minutes (in milliseconds)
  @timeout 1000 * 60 * 30

  # 30 seconds (for testing)
  @timeout 1000 * 30
  def init(room_id) do
    room =
      Dopamine.Repo.get(Dopamine.Rooms.Room, room_id)
      |> Dopamine.Repo.preload([:memberships, events: all_events_query()])

    IO.puts("Room server for room '#{room.matrix_id}' coming online.")
    IO.inspect(room.matrix_id)
    IO.puts("Room state:")
    IO.inspect(room.state)
    IO.inspect(room)

    Registry.register(Dopamine.MatrixRegistry, room.matrix_id, self())

    state = %__MODULE__{room: room}
    {:ok, state, @timeout}
  end

  def handle_call(:get_visibility, _sender, state) do
    {:reply, state.room.public, state, @timeout}
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

  def handle_call({:get_state, type, state_key}, _sender, state) do
    {:reply, {:ok}, state, @timeout}
  end

  def handle_call(:all_events, _sender, state) do
    {:reply, state.room.events, state, @timeout}
  end

  def handle_info(:timeout, state) do
    IO.puts("Room server shutting down, timed out...")
    {:stop, {:shutdown, "Server timed out."}, state}
  end

  defp all_events_query() do
    import Ecto.Query, only: [from: 2]

    from(e in Dopamine.Rooms.Event, order_by: [e.depth, e.inserted_at])
  end
end
