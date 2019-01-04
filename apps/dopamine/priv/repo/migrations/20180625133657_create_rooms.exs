defmodule Dopamine.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:public, :boolean, null: false)
      add(:matrix_id, :string, null: false)

      timestamps()
    end

    create(index(:rooms, [:public]))
    create(unique_index(:rooms, [:matrix_id]))
  end
end
