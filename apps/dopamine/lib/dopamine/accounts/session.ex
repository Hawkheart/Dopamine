defmodule Dopamine.Accounts.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias :crypto, as: Crypto


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sessions" do
    field :creation_time, :utc_datetime
    field :device_id, :string
    field :token, :string
    belongs_to :user, Dopamine.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:device_id, :creation_time, :token])
    |> validate_required([:device_id, :creation_time, :token])
    |> unique_constraint(:token)
  end

  def create_changeset(session, attrs) do
    session
    |> change(creation_time: DateTime.utc_now())
    |> change(token: Base.encode16(Crypto.strong_rand_bytes(16)))
    |> put_assoc(:user, attrs.user)
    |> changeset(attrs)
  end

end
