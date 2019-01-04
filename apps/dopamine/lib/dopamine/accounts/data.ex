defmodule Dopamine.Accounts.Data do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "account_data" do
    field :content, :map
    field :type, :string
    field :room_id, :binary_id
    field :user_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:type, :content])
    |> validate_required([:type, :content])
  end
end
