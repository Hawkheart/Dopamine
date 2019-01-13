defmodule Dopamine.Rooms.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "memberships" do
    field(:status, :string)

    belongs_to(:room, Dopamine.Rooms.Room)
    belongs_to(:user, Dopamine.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:status, :room_id, :user_id])
    |> validate_required([:status, :room_id, :user_id])
    |> unique_constraint(:user_id, name: :memberships_user_room_index)
  end
end
