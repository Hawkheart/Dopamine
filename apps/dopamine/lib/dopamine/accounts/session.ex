defmodule Dopamine.Accounts.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias :crypto, as: Crypto

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sessions" do
    field(:creation_time, :utc_datetime)
    field(:token, :string)
    belongs_to(:user, Dopamine.Accounts.User)
    belongs_to(:device, Dopamine.Accounts.Device)

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:creation_time, :token])
    |> validate_required([:creation_time, :token])
    |> assoc_constraint(:user)
    |> assoc_constraint(:device)
    |> unique_constraint(:token)
  end

  def creation_changeset(session, attrs) do
    now =
      DateTime.utc_now()
      |> DateTime.truncate(:second)

    session
    |> change(creation_time: now)
    |> change(token: Base.encode16(Crypto.strong_rand_bytes(16)))
    |> cast(attrs, [:user_id, :device_id])
    |> changeset(attrs)
  end
end
