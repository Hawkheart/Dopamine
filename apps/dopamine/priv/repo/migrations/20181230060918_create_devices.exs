defmodule Dopamine.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:last_ip, :string)
      add(:last_time, :utc_datetime)
      add(:user_id, references(:users, on_delete: :nothing, type: :binary_id))
      add(:public_id, :string)

      timestamps()
    end

    create(index(:devices, [:user_id]))
    create(unique_index(:devices, [:public_id]))
  end
end
