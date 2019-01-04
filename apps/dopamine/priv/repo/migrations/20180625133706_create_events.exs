defmodule Dopamine.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:depth, :integer)
      add(:content, :map)
      add(:unsigned, :map)
      add(:origin_timestamp, :integer)
      add(:sender, :string)
      add(:state_key, :string)
      add(:type, :string)
      add(:room_id, references(:rooms, on_delete: :nothing, type: :binary_id))

      timestamps()
    end

    create(index(:events, [:room_id]))
  end
end
