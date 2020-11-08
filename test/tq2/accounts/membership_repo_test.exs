defmodule Tq2.Accounts.MembershipRepoTest do
  use Tq2.DataCase

  describe "membership" do
    alias Tq2.Accounts
    alias Tq2.Accounts.{Account, Membership, Session}

    @valid_attrs %{
      email: "some@email.com",
      lastname: "some lastname",
      name: "some name",
      password: "123456"
    }

    def user_fixture() do
      account = Tq2.Repo.get_by!(Account, name: "test_account")
      session = %Session{account: account}

      {:ok, user} = Accounts.create_user(session, @valid_attrs)

      %{user | password: nil}
    end

    test "assigns default to true when user does not exists" do
      attrs = Membership.put_create_user_attrs(%Account{}, @valid_attrs)

      assert List.first(attrs.memberships).default
    end

    test "assigns default to false when user exists" do
      user_fixture()
      attrs = Membership.put_create_user_attrs(%Account{}, @valid_attrs)

      refute List.first(attrs.memberships).default
    end
  end
end
