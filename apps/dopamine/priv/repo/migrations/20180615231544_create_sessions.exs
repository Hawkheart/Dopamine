defmodule Dopamine.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_id, :string
      add :creation_time, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :token, :string

      timestamps()
    end

    create index(:sessions, [:user_id])
    create unique_index(:sessions, [:token])
  end
end
