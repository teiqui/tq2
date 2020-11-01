defmodule Tq2.AccountsTest do
  use Tq2.DataCase

  alias Tq2.Accounts

  describe "accounts" do
    alias Tq2.Accounts.Account

    @valid_attrs %{
      country: "ar",
      name: "some name",
      status: "active",
      time_zone: "America/Argentina/Mendoza"
    }
    @update_attrs %{
      country: "mx",
      name: "some updated name",
      status: "green",
      time_zone: "America/Argentina/Cordoba"
    }
    @invalid_attrs %{country: nil, name: nil, status: nil, time_zone: nil}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_account()

      account
    end

    test "list_accounts/1 returns all accounts" do
      account = account_fixture()
      assert Accounts.list_accounts(%{}).entries == [account]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Accounts.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account" do
      assert {:ok, %Account{} = account} = Accounts.create_account(@valid_attrs)
      assert account.country == "ar"
      assert account.name == "some name"
      assert account.status == "active"
      assert account.time_zone == "America/Argentina/Mendoza"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      assert {:ok, %Account{} = account} = Accounts.update_account(account, @update_attrs)
      assert account.country == "mx"
      assert account.name == "some updated name"
      assert account.status == "green"
      assert account.time_zone == "America/Argentina/Cordoba"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)
      assert account == Accounts.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Accounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end
  end

  describe "users" do
    alias Tq2.Accounts.User

    @valid_attrs %{
      email: "some@email.com",
      lastname: "some lastname",
      name: "some name",
      password: "123456"
    }
    @update_attrs %{
      email: "new@email.com",
      lastname: "some updated lastname",
      name: "some updated name"
    }
    @invalid_attrs %{email: "wrong@email", lastname: nil, name: nil, password: "123"}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      %{user | password: nil}
    end

    test "list_users/1 returns all users" do
      user = user_fixture()
      assert Accounts.list_users(%{}).entries == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some@email.com"
      assert user.lastname == "some lastname"
      assert user.name == "some name"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "new@email.com"
      assert user.lastname == "some updated lastname"
      assert user.name == "some updated name"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
