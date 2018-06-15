defmodule Dopamine.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :display_name, :string
    field :hash, :string
    field :username, :string

    timestamps()
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
    |> put_password_hash(attrs.password)
    |> changeset(attrs)
  end

  defp put_password_hash(changeset, password) do
    change(changeset, Comeonin.Argon2.add_hash(password, hash_key: :hash))
  end

end
