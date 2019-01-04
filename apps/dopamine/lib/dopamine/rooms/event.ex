defmodule Dopamine.Rooms.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "events" do
    field(:content, :map)
    field(:unsigned, :map)
    field(:depth, :integer)
    field(:origin_timestamp, :integer)
    field(:sender, :string)
    field(:state_key, :string)
    field(:type, :string)
    belongs_to(:room, Dopamine.Rooms.Room)

    timestamps()
  end

  @fields [:content, :unsigned, :depth, :origin_timestamp, :sender, :state_key, :type, :room_id]
  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
