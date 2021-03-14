defmodule Tq2.Notifications.CustomerSubscriptionTest do
  use Tq2.DataCase, async: true

  describe "subscription customer" do
    alias Tq2.Notifications.CustomerSubscription

    @valid_attrs %{
      customer_id: "1"
    }
    @invalid_attrs %{
      customer_id: nil
    }

    test "changeset with valid attributes" do
      changeset = CustomerSubscription.changeset(%CustomerSubscription{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = CustomerSubscription.changeset(%CustomerSubscription{}, @invalid_attrs)

      refute changeset.valid?
    end
  end
end
