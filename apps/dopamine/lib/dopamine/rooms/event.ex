defmodule Dopamine.Rooms.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "events" do
    field(:matrix_id, :string)
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
    |> put_change(:matrix_id, generate_mxid())
    |> put_change(:origin_timestamp, DateTime.utc_now())
    |> changeset(attrs)
  end

  # TODO - put this all together
  defp generate_mxid do
    id = :crypto.strong_rand_bytes(16) |> Base.encode16()
    domain = Application.get_env(:dopamine, :domain, "localhost")
    "$#{id}:#{domain}"
  end
end
