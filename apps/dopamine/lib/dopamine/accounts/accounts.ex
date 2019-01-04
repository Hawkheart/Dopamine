defmodule Dopamine.Accounts do
  alias Dopamine.Accounts.User
  alias Dopamine.Accounts.Session
  alias Dopamine.Accounts.Device

  alias Ecto.Multi

  def get(username) do
    Dopamine.Repo.get_by(User, username: username)
  end

  def create_user(username, password, device_id) do
    user = %User{}

    user_changeset =
      User.creation_changeset(user, %{
        username: username,
        password: password
      })

    multi =
      Multi.new()
      |> Multi.insert(:user, user_changeset)
      |> Multi.run(:device, fn repo, %{user: user} ->
        device_changeset =
          Device.creation_changeset(%Device{}, %{public_id: device_id, user_id: user.id})

        repo.insert(device_changeset)
      end)
      |> Multi.run(:session, fn repo, %{user: user, device: device} ->
        session_changeset =
          Session.creation_changeset(%Session{}, %{device_id: device.id, user_id: user.id})

        repo.insert(session_changeset)
      end)

    Dopamine.Repo.transaction(multi)
  end

  def set_name(user, new_name) do
    user
    |> User.changeset(%{display_name: new_name})
    |> Dopamine.Repo.update!()
  end

  @spec verify_user(String.t(), String.t()) :: tuple()
  def verify_user(username, password) do
    with user when not is_nil(user) <- get(username) do
      check_password(user, password)
    else
      # Without a user, just perform a dummy check and return.
      _ ->
        Comeonin.Argon2.dummy_checkpw()
        {:error, :no_user}
    end
  end

  @spec check_password(any(), String.t()) :: tuple()
  defp check_password(user = %User{}, password) do
    case Comeonin.Argon2.check_pass(user, password, hash_key: :hash) do
      {:ok, user} -> {:ok, user}
      {:error, _msg} -> {:error, :bad_pass}
    end
  end

  def set_presence(user, {presence, status_msg}) do
    changeset = User.presence_changeset(user, %{presence: presence, status_msg: status_msg})
    Dopamine.Repo.update(changeset)
  end

  def create_device(user, device_id) do
    device = %{public_id: device_id, user: user}
    changeset = Device.creation_changeset(%Device{}, device)
    Dopamine.Repo.insert(changeset)
  end

  def create_session(user, device) do
    session = %Session{}
    changeset = Session.creation_changeset(session, %{device_id: device.id, user_id: user.id})
    Dopamine.Repo.insert(changeset)
  end

  @spec delete_session(Dopamine.Accounts.Session.t()) :: any()
  def delete_session(session) do
    Dopamine.Repo.delete(session)
  end

  def get_session(token) do
    Dopamine.Repo.get_by(Session, token: token)
    |> Dopamine.Repo.preload([:user, :device])
  end
end
