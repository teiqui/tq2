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
end
