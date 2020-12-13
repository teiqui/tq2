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
  end
end
