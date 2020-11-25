defmodule Tq2.Accounts.MembershipRepoTest do
  use Tq2.DataCase

  import Tq2.Fixtures,
    only: [
      user_valid_attrs: 0,
      user_fixture: 1,
      create_session: 1
    ]

  describe "membership" do
    alias Tq2.Accounts.Membership

    setup [:create_session]

    test "assigns default to true when user does not exists", %{session: session} do
      attrs = Membership.put_create_user_attrs(session.account, user_valid_attrs())

      assert List.first(attrs.memberships).default
    end

    test "assigns default to false when user exists", %{session: session} do
      user_fixture(session)
      attrs = Membership.put_create_user_attrs(session.account, user_valid_attrs())

      refute List.first(attrs.memberships).default
    end

    test "assigns owner to true when user is the first for the account", %{session: session} do
      attrs = Membership.put_create_user_attrs(session.account, user_valid_attrs())

      assert List.first(attrs.memberships).owner
    end

    test "assigns default to false when user is not the first for the account", %{
      session: session
    } do
      user_fixture(session)

      attrs = Membership.put_create_user_attrs(session.account, user_valid_attrs())

      refute List.first(attrs.memberships).owner
    end
  end
end
