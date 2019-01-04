defmodule Dopamine.Filters.Filter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "filters" do
    field(:account_data, :map)
    field(:event_fields, {:array, :string})
    field(:event_format, :string)
    field(:presence, :map)
    field(:room, :map)

    belongs_to(:user, Dopamine.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(filter, attrs) do
    filter
    |> cast(attrs, [:event_fields, :event_format, :presence, :account_data, :room, :user_id])
    |> validate_required([:user_id])
  end
end
