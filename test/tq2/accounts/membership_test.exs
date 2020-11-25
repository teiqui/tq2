defmodule Tq2.Accounts.MembershipTest do
  use Tq2.DataCase, async: true

  describe "membership" do
    alias Tq2.Accounts.Membership

    @valid_attrs %{
      default: true,
      owner: true,
      account_id: "1",
      user_id: "1"
    }
    @invalid_attrs %{
      default: nil,
      owner: nil,
      account_id: nil,
      user_id: nil
    }

    test "changeset with valid attributes" do
      changeset = Membership.changeset(%Membership{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Membership.changeset(%Membership{}, @invalid_attrs)

      refute changeset.valid?
    end
  end
end
