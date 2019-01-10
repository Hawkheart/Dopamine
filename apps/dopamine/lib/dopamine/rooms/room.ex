defmodule Dopamine.Rooms.RoomState do
  @behaviour Ecto.Type
  @derive Jason.Encoder
  use Dopamine.Schema

  @primary_key false
  embedded_schema do
    field(:current_id, Dopamine.MatrixID)
    field(:prev_id, Dopamine.MatrixID)
    field(:content, :map)
  end

  def changeset(data, attrs) do
    import Ecto.Changeset

    data
    |> cast(attrs, [:current_id, :prev_id, :content])
    |> validate_required([:current_id, :content])
  end

  def type, do: :map

  def cast(input) when is_map(input) do
    changeset =
      %__MODULE__{}
      |> changeset(input)

    if changeset.valid? do
      data = Ecto.Changeset.apply_changes(changeset)
      {:ok, data}
    else
      {:error, :invalid}
    end
  end

  def dump(input = %__MODULE__{}) do
    {:ok, Map.from_struct(input)}
  end

  def load(input) when is_map(input) do
    data = for {key, value} <- input, do: {String.to_existing_atom(key), value}, into: %{}
    {:ok, struct!(__MODULE__, data)}
  end
end

defmodule Dopamine.Rooms.Room do
  use Dopamine.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field(:public, :boolean, default: false)
    field(:matrix_id, Dopamine.MatrixID)

    field(:state, {:map, Dopamine.Rooms.RoomState})

    has_many(:events, Dopamine.Rooms.Event)
    has_many(:memberships, Dopamine.Rooms.Membership)

    timestamps()
  end
end
