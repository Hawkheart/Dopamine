defmodule Dopamine.Rooms.Room do
  use Dopamine.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id
  schema "rooms" do
    field(:public, :boolean, default: false)
    field(:matrix_id, :string)

    has_many(:events, Dopamine.Rooms.Event)
    has_many(:memberships, Dopamine.Rooms.Membership)

    timestamps()
  end
end
