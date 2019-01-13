defmodule Dopamine.Rooms.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "events" do
    field(:matrix_id, Dopamine.MatrixID)
    field(:content, :map)
    field(:prev_content, :map)
    field(:unsigned, :map)
    field(:depth, :integer)
    field(:origin_timestamp, :utc_datetime_usec)
    field(:sender, :string)
    field(:state_key, :string)
    field(:type, :string)
    belongs_to(:room, Dopamine.Rooms.Room)

    timestamps()
  end

  @fields [
    :matrix_id,
    :content,
    :prev_content,
    :unsigned,
    :depth,
    :origin_timestamp,
    :sender,
    :state_key,
    :type,
    :room_id
  ]
  @doc false
  def changeset(event, attrs) do
    event
    |> change()
    |> Map.put(:empty_values, [])
    |> cast(attrs, @fields)
    |> validate_required([:matrix_id, :depth, :origin_timestamp, :type, :content])
  end

  def creation_changeset(event, attrs) do
    event
    |> change()
    |> add_matrix_id()
    |> put_change(:origin_timestamp, DateTime.utc_now())
    |> changeset(attrs)
  end

  def state_event?(%__MODULE__{state_key: key}) when is_nil(key) do
    false
  end

  def state_event?(_), do: true

  defp add_matrix_id(changeset) do
    if Ecto.Changeset.get_field(changeset, :matrix_id) == nil do
      Ecto.Changeset.put_change(changeset, :matrix_id, Dopamine.MatrixID.generate(:event))
    else
      changeset
    end
  end
end
