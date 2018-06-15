defmodule Dopamine.Accounts.Session do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sessions" do
    field :creation_time, :utc_datetime
    field :device_id, :string
    field :user_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:device_id, :creation_time])
    |> validate_required([:device_id, :creation_time])
  end

  def create_changeset(session, attrs) do
    session
    |> change(creation_time: DateTime.utc_now())
    # TODO : real device IDs
    |> change(device_id: "asdf")
    |> changeset(attrs)
  end
end
