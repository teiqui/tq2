defmodule Tq2.Shops.ConfigurationTest do
  use Tq2.DataCase, async: true

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
      pay_on_delivery: true
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

    test "changeset with valid attributes" do
      changeset = Configuration.changeset(%Configuration{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Configuration.changeset(%Configuration{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:pickup_time_limit, String.duplicate("a", 256))
        |> Map.put(:delivery_time_limit, String.duplicate("a", 256))

      changeset = Configuration.changeset(%Configuration{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).pickup_time_limit
      assert "should be at most 255 character(s)" in errors_on(changeset).delivery_time_limit
    end

    test "changeset should has at least one active" do
      attrs =
        @valid_attrs
        |> Map.put(:pickup, false)
        |> Map.put(:delivery, false)

      changeset = Configuration.changeset(%Configuration{}, attrs)

      assert "must be at least one enabled: Pickup / Delivery" in errors_on(changeset).pickup
    end

    test "changeset should required pickup time limit with pickup" do
      attrs =
        @valid_attrs
        |> Map.put(:pickup_time_limit, "")

      changeset = Configuration.changeset(%Configuration{}, attrs)

      assert "can't be blank" in errors_on(changeset).pickup_time_limit
    end

    test "changeset should required delivery time limit with delivery" do
      attrs =
        @valid_attrs
        |> Map.put(:delivery_time_limit, "")

      changeset = Configuration.changeset(%Configuration{}, attrs)

      assert "can't be blank" in errors_on(changeset).delivery_time_limit
    end

    test "changeset should required delivery area with delivery" do
      attrs =
        @valid_attrs
        |> Map.put(:delivery_area, "")

      changeset = Configuration.changeset(%Configuration{}, attrs)

      assert "can't be blank" in errors_on(changeset).delivery_area
    end
  end
end
