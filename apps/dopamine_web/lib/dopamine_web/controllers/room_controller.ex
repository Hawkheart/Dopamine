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
      field(:invite_3pid, {:array, Forms.Invite3pid})
      field(:initial_state, {:array, Forms.StateEvent})
    end

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
        :initial_state
      ])
      |> validate_inclusion(:visibility, ["public", "private"])
      |> validate_inclusion(:preset, ["private_chat", "public_chat", "trusted_private_chat", nil])
    end
  end

  def create(conn, data) do
    args = %CreateRoomArgs{} |> CreateRoomArgs.changeset(data) |> Ecto.Changeset.apply_changes()
    IO.inspect(args)
    user = conn.assigns.user
    Dopamine.Rooms.create_room(user, args)
    conn |> json(%{})
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
