defmodule Tq2.Shops.ConfigurationTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [default_account: 1]

  describe "configuration" do
    alias Tq2.Shops.Configuration

    @valid_attrs %{
      require_email: true,
      require_phone: true,
      pickup: true,
      pickup_time_limit: "some time limit",
      address: "some address",
      delivery: true,
      delivery_area: "some delivery area",
      delivery_time_limit: "some time limit",
      pay_on_delivery: true,
      shippings: %{"0" => %{"name" => "Anywhere", "price" => "10.00"}}
    }
    @invalid_attrs %{
      require_email: nil,
      require_phone: nil,
      pickup: nil,
      pickup_time_limit: String.duplicate("a", 256),
      address: nil,
      delivery: nil,
      delivery_area: nil,
      delivery_time_limit: String.duplicate("a", 256),
      pay_on_delivery: nil
    }

    setup [:default_account]

    test "changeset with valid attributes", %{account: account} do
      changeset = Configuration.changeset(%Configuration{}, @valid_attrs, account)

      assert changeset.valid?
    end

    test "changeset with invalid attributes", %{account: account} do
      changeset = Configuration.changeset(%Configuration{}, @invalid_attrs, account)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:pickup_time_limit, String.duplicate("a", 256))
        |> Map.put(:delivery_time_limit, String.duplicate("a", 256))

      changeset = Configuration.changeset(%Configuration{}, attrs, account)

      assert "should be at most 255 character(s)" in errors_on(changeset).pickup_time_limit
      assert "should be at most 255 character(s)" in errors_on(changeset).delivery_time_limit
    end

    test "changeset should has at least one active", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:pickup, false)
        |> Map.put(:delivery, false)

      changeset = Configuration.changeset(%Configuration{}, attrs, account)

      assert "must have at least one enabled: Pickup / Delivery" in errors_on(changeset).pickup
    end

    test "changeset should required pickup time limit with pickup", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:pickup_time_limit, "")

      changeset = Configuration.changeset(%Configuration{}, attrs, account)

      assert "can't be blank" in errors_on(changeset).pickup_time_limit
    end

    test "changeset should required delivery time limit with delivery", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:delivery_time_limit, "")

      changeset = Configuration.changeset(%Configuration{}, attrs, account)

      assert "can't be blank" in errors_on(changeset).delivery_time_limit
    end

    test "changeset should required delivery area with delivery", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:delivery_area, "")

      changeset = Configuration.changeset(%Configuration{}, attrs, account)

      assert "can't be blank" in errors_on(changeset).delivery_area
    end

    test "changeset should required at least one shipping", %{account: account} do
      attrs = @valid_attrs |> Map.put(:shippings, nil)

      changeset = Configuration.changeset(%Configuration{}, attrs, account)

      assert "Add at least one shipping" in errors_on(changeset).shippings
    end
  end
end
