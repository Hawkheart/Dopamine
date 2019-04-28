alias DopamineWeb.Forms

defmodule DopamineWeb.RoomController do
  use DopamineWeb, :controller

  defmodule CreateRoomArgs do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field(:visibility, :string, default: "private")
      field(:room_alias_name, :string)
      field(:name, :string)
      field(:topic, :string)
      field(:invite, {:array, :string})
      field(:room_version, :string)
      field(:creation_content, :map)
      field(:preset, :string)
      field(:is_direct, :boolean)
      field(:power_level_content_override, :map, default: %{})
      field(:invite_3pid, {:array, Forms.Invite3pid})
      field(:initial_state, {:array, Forms.StateEvent}, default: [])
    end

    @spec changeset(
            {map(), map()}
            | %{:__struct__ => atom() | %{__changeset__: map()}, optional(atom()) => any()},
            :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
          ) :: Ecto.Changeset.t()
    def changeset(data, attrs) do
      data
      |> cast(attrs, [
        :visibility,
        :room_alias_name,
        :name,
        :topic,
        :invite,
        :room_version,
        :creation_content,
        :preset,
        :is_direct,
        :invite_3pid,
        :initial_state,
        :power_level_content_override
      ])
      |> validate_inclusion(:visibility, ["public", "private"])
      |> validate_inclusion(:preset, ["private_chat", "public_chat", "trusted_private_chat", nil])
    end
  end

  def create(conn, data) do
    args = %CreateRoomArgs{} |> CreateRoomArgs.changeset(data) |> Ecto.Changeset.apply_changes()
    IO.inspect(args)
    user = conn.assigns.user
    {:ok, room_id} = Dopamine.Rooms.create_room(user, args)

    conn |> json(%{room_id: room_id})
  end

  def send_event(conn, _data) do
    # TODO - permissions check

    %{"room_id" => room_mxid, "type" => type} = conn.path_params
    content = conn.body_params

    {:ok, room_pid} = Dopamine.Rooms.get_room(room_mxid)

    user_id = Dopamine.Accounts.User.matrix_id(conn.assigns.user)

    attrs = %{
      content: content,
      unsigned: %{},
      sender: user_id,
      state_key: nil,
      type: type
    }

    {:ok, event} = Dopamine.Rooms.Server.insert_event!(room_pid, attrs)

    conn |> json(%{event_id: event.matrix_id})
  end

  def set_state(conn, _data) do
    %{"room_id" => room_id, "type" => type} = conn.path_params
    state_key = Map.get(conn.path_params, "state_key", "")
    content = conn.body_params
    user_id = Dopamine.Accounts.User.matrix_id(conn.assigns.user)

    attrs = %{content: content, unsigned: %{}, sender: user_id, state_key: state_key, type: type}

    {:ok, room_pid} = Dopamine.Rooms.get_room(room_id)
    {:ok, event} = Dopamine.Rooms.Server.insert_event!(room_pid, attrs)
    conn |> json(%{event_id: event.matrix_id})
  end

  def get_public(conn, _data) do
    public_rooms =
      Dopamine.Rooms.public_rooms()
      |> Dopamine.Repo.preload(:memberships)

    total_room_count_estimate = length(public_rooms)

    chunks =
      Enum.map(public_rooms, fn room ->
        {:ok, room_pid} = Dopamine.Rooms.get_room(room.matrix_id)
        {:ok, name_content} = Dopamine.Rooms.Server.get_state(room_pid, "m.room.name")

        name = if name_content, do: name_content["name"]

        %{
          room_id: room.matrix_id,
          num_joined_members: member_count(room),
          world_readable: false,
          guest_can_join: false,
          name: name
        }
      end)

    IO.inspect(chunks)

    conn |> json(%{total_room_count_estimate: total_room_count_estimate, chunk: chunks})
  end

  def get_visibility(conn, _data) do
    room_id = conn.path_params["room_id"]
    {:ok, room} = Dopamine.Rooms.get_room(room_id)

    public = GenServer.call(room, :get_visibility)

    vis = if public, do: "public", else: "private"
    conn |> json(%{visibility: vis})
  end

  def set_visibility(conn, data) do
    room_id = conn.path_params["room_id"]
    {:ok, room} = Dopamine.Rooms.get_room(room_id)

    public = data["visibility"] == "public"

    :ok = GenServer.call(room, {:set_visibility, public})
    conn |> json(%{})
  end

  defp member_count(room) do
    Enum.filter(room.memberships, fn x -> x.status == "joined" end) |> length
  end

  def join(conn, _data) do
    import Ecto.Query, only: [from: 2]
    room_mxid = conn.path_params["room_id"]

    {:ok, room_pid} = Dopamine.Rooms.get_room(room_mxid)

    room =
      Dopamine.Repo.one!(from(r in Dopamine.Rooms.Room, where: r.matrix_id == ^room_mxid))
      |> Dopamine.Repo.preload([:memberships, memberships: [:user]])

    user_mxid = Dopamine.Accounts.User.matrix_id(conn.assigns.user)

    attrs = %{
      content: %{"membership" => "join"},
      unsigned: %{},
      state_key: user_mxid,
      sender: user_mxid,
      type: "m.room.member"
    }

    {:ok, _event} = Dopamine.Rooms.Server.insert_event!(room_pid, attrs)

    conn |> json(%{})
  end

  def initial_sync(conn, _data) do
    room_id = conn.path_params["room_id"]
    conn |> json(%{room_id: room_id})
  end
end

defmodule DopamineWeb.Forms.StateEvent do
  @behaviour Ecto.Type
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:type, :string)
    field(:state_key, :string, default: "")
    field(:content, :map)
  end

  def type, do: :map

  def cast(input) when is_map(input) do
    changeset =
      %__MODULE__{}
      |> cast(input, [:type, :state_key, :content])
      |> validate_required([:type, :state_key])

    if changeset.valid?, do: {:ok, apply_changes(changeset)}, else: :error
  end

  def cast(_), do: :error

  def load(data) when is_map(data) do
    IO.inspect(data)
    :error
  end

  def dump(%__MODULE__{} = data) do
    {:ok, Map.from_struct(data)}
  end

  def dump(_), do: :error
end

defmodule DopamineWeb.Forms.Invite3pid do
  @behaviour Ecto.Type
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:id_server, :string)
    field(:medium, :string)
    field(:address, :string)
  end

  def type, do: :map

  def cast(input) when is_map(input) do
    changeset =
      %__MODULE__{}
      |> cast(input, [:id_server, :medium, :address])
      |> validate_required([:id_server, :medium, :string])

    if changeset.valid?, do: {:ok, apply_changes(changeset)}, else: :error
  end

  def cast(_), do: :error

  def load(input) when is_map(input) do
    IO.inspect(input)
    :error
  end

  def dump(%__MODULE__{} = input) do
    {:ok, Map.from_struct(input)}
  end

  def dump(_), do: :error
end
