defmodule Dopamine.Accounts do
  alias Dopamine.Accounts.User

  def get(username) do
    Dopamine.Repo.get_by(User, username: username)
  end

  def create_user(username, password) do
    user = %User{}
    changeset = User.creation_changeset(user, %{username: username, password: password})
    case Dopamine.Repo.insert(changeset) do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> IO.inspect(changeset.errors);{:error, :db_failed}
    end
  end

  def verify_user(username, password) do
    user = get username
    check_password(user, password)
  end

  defp check_password(user = %User{}, password) do
    case Comeonin.Argon2.check_pass(user, password, hash_key: :hash) do
      {:ok, user} -> {:ok, user}
      {:error, msg} -> IO.puts msg; {:error, :bad_pass}
    end
  end

  # No user exists. Perform a dummy hashing and return.
  defp check_password(nil, _password) do
    Comeonin.Argon2.dummy_checkpw()
    {:error, :bad_pass}
  end

end
