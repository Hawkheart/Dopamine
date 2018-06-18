defmodule Dopamine.Accounts do
  alias Dopamine.Accounts.User
  alias Dopamine.Accounts.Session

  def get(username) do
    Dopamine.Repo.get_by(User, username: username)
  end

  def create_user(username, password) do
    user = %User{}
    changeset = User.creation_changeset(user, %{username: username, password: password})
    Dopamine.Repo.insert changeset
  end

  def verify_user(username, password) do
    with user when not is_nil(user) <- get(username) do
      check_password(user, password)
    else
        # Without a user, just perform a dummy check and return.
      _ -> Comeonin.Argon2.dummy_checkpw()
           {:error, :no_user}
    end
  end

  defp check_password(user = %User{}, password) do
    case Comeonin.Argon2.check_pass(user, password, hash_key: :hash) do
      {:ok, user} -> {:ok, user}
      {:error, _msg} -> {:error, :bad_pass}
    end
  end

  def create_session(user = %User{}, device_id) do
    session = %Session{}
    changeset = Session.create_changeset(session, %{device_id: device_id, user: user})
    Dopamine.Repo.insert(changeset)
  end

  def delete_session(session) do
    Dopamine.Repo.delete session
  end

  def get_session(token) do
    Dopamine.Repo.get_by(Session, token: token)
    |> Dopamine.Repo.preload(:user)
  end

end
