defmodule DopamineTest.User do
  use Dopamine.DataCase

  alias Dopamine.Accounts

  setup do
    Accounts.create_user("hawkheart", "password", "my device")
  end

  test "rejects mixed case username" do
    assert {:error, :user, changeset, _} =
             Accounts.create_user("Username", "password!!!", "AGOODDEVICEID")

    assert "must be lowercase" in errors_on(changeset).username
  end

  test "rejects short password" do
    assert {:error, :user, changeset, _} = Accounts.create_user("username", "pass", "AGOODDEVICE")
    assert "is too short" in errors_on(changeset).password
  end

  test "cannot create duplicate users" do
    assert {:error, :user, changeset, _} =
             Accounts.create_user("hawkheart", "anypassword", "a device")

    assert "has already been taken" in errors_on(changeset).username
  end

  test "can log in to account", %{user: user} do
    assert {:ok, logged_in_user} = Accounts.verify_user("hawkheart", "password")

    assert user.id == logged_in_user.id
  end

  test "can't log in without correct password" do
    assert {:error, :bad_pass} == Accounts.verify_user("hawkheart", "")
    assert {:error, :bad_pass} == Accounts.verify_user("hawkheart", "literally anything")
  end

  test "can't log in to nonexistent account" do
    assert {:error, :no_user} == Accounts.verify_user("asdf", "some password...")
  end
end
