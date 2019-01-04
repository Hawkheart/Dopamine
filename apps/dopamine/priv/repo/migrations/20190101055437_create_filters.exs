defmodule Dopamine.Repo.Migrations.CreateFilters do
  use Ecto.Migration

  def change do
    create table(:filters, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:account_data, :map)
      add(:event_fields, {:array, :string})
      add(:event_format, :string)
      add(:presence, :map)
      add(:room, :map)
      add(:user_id, references(:users, on_delete: :nothing, type: :binary_id))

      timestamps()
    end

    create(index(:filters, [:user_id]))
  end
end
