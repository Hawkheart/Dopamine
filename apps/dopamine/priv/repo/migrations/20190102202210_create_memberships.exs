defmodule Dopamine.Repo.Migrations.CreateMemberships do
  use Ecto.Migration

  def change do
    create table(:memberships, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:status, :string)
      add(:room_id, references(:rooms, on_delete: :nothing, type: :binary_id))
      add(:user_id, references(:users, on_delete: :nothing, type: :binary_id))

      timestamps()
    end

    create(index(:memberships, [:room_id]))
    create(index(:memberships, [:user_id]))
    create(unique_index(:memberships, [:room_id, :user_id], name: :memberships_user_room_index))
  end
end
