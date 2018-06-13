defmodule Dopamine.FormsTest do
  use Dopamine.DataCase

  alias Dopamine.Forms

  describe "registrations" do
    alias Dopamine.Forms.Registration

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def registration_fixture(attrs \\ %{}) do
      {:ok, registration} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Forms.create_registration()

      registration
    end

    test "list_registrations/0 returns all registrations" do
      registration = registration_fixture()
      assert Forms.list_registrations() == [registration]
    end

    test "get_registration!/1 returns the registration with given id" do
      registration = registration_fixture()
      assert Forms.get_registration!(registration.id) == registration
    end

    test "create_registration/1 with valid data creates a registration" do
      assert {:ok, %Registration{} = registration} = Forms.create_registration(@valid_attrs)
    end

    test "create_registration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Forms.create_registration(@invalid_attrs)
    end

    test "update_registration/2 with valid data updates the registration" do
      registration = registration_fixture()
      assert {:ok, registration} = Forms.update_registration(registration, @update_attrs)
      assert %Registration{} = registration
    end

    test "update_registration/2 with invalid data returns error changeset" do
      registration = registration_fixture()
      assert {:error, %Ecto.Changeset{}} = Forms.update_registration(registration, @invalid_attrs)
      assert registration == Forms.get_registration!(registration.id)
    end

    test "delete_registration/1 deletes the registration" do
      registration = registration_fixture()
      assert {:ok, %Registration{}} = Forms.delete_registration(registration)
      assert_raise Ecto.NoResultsError, fn -> Forms.get_registration!(registration.id) end
    end

    test "change_registration/1 returns a registration changeset" do
      registration = registration_fixture()
      assert %Ecto.Changeset{} = Forms.change_registration(registration)
    end
  end
end
