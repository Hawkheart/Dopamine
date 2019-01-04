defmodule Dopamine.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field(:display_name, :string)
    field(:password, :string, virtual: true)
    field(:hash, :string)
    field(:username, :string)

    # presence.
    field(:status_msg, :string)
    field(:presence, :string, default: "unavailable")

    has_many(:sessions, Dopamine.Accounts.Session)
    has_many(:devices, Dopamine.Accounts.Device)

    has_many(:account_data, Dopamine.Accounts.Data)
    has_many(:memberships, Dopamine.Rooms.Membership)

    timestamps()
  end

  def matrix_id(user) do
    domain = Application.get_env(:dopamine, :hostname, "localhost")
    "@#{user.username}:#{domain}"
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :display_name, :hash])
    |> validate_required([:username, :hash])
    |> validate_length(:username, min: 1, max: 128)
    |> validate_format(:username, ~r(^[a-z0-9-.=_/]+$))
    |> unique_constraint(:username)
  end

  @doc false
  def creation_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_length(:password, min: 8)
    |> put_password_hash()
    |> put_change(:display_name, attrs.username)
    |> cast_assoc(:devices, with: &Dopamine.Accounts.Device.creation_changeset/2)
    |> changeset(attrs)
  end

  def presence_changeset(user, attrs) do
    user
    |> cast(attrs, [:status_msg, :presence])
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        change(changeset, Comeonin.Argon2.add_hash(pass, hash_key: :hash))

      _ ->
        changeset
    end
  end
end
