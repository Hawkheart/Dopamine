defmodule Dopamine.Repo.Migrations.CreateAccountData do
  use Ecto.Migration

  def change do
    create table(:account_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :content, :map
      add :room_id, references(:rooms, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:account_data, [:room_id])
    create index(:account_data, [:user_id])
  end
end
