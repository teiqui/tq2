defmodule Tq2.Notifications.SubscriptionUserTest do
  use Tq2.DataCase, async: true

  describe "subscription user" do
    alias Tq2.Notifications.SubscriptionUser

    @valid_attrs %{
      user_id: "1"
    }
    @invalid_attrs %{
      user_id: nil
    }

    test "changeset with valid attributes" do
      changeset = SubscriptionUser.changeset(%SubscriptionUser{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = SubscriptionUser.changeset(%SubscriptionUser{}, @invalid_attrs)

      refute changeset.valid?
    end
  end
end
