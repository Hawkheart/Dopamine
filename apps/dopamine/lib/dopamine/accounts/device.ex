defmodule Dopamine.Accounts.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "devices" do
    field(:last_ip, :string)
    field(:last_time, :utc_datetime)
    field(:name, :string)
    # The "ID" the client sees/gives.
    field(:public_id, :string)

    has_many(:sessions, Dopamine.Accounts.Session)
    belongs_to(:user, Dopamine.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:name, :last_ip, :last_time, :public_id])
    |> validate_required([:name, :last_ip, :last_time, :public_id])
    |> unique_constraint(:public_id)
  end

  def creation_changeset(data, attrs) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    data
    |> cast(attrs, [:user_id])
    |> cast(%{last_ip: ":>", last_time: now, name: ":>"}, [:last_ip, :last_time, :name])
    |> changeset(attrs)
  end
end
