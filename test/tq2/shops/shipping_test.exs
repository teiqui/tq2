defmodule Tq2.Shops.ShippingTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [default_account: 1]

  describe "shipping" do
    alias Tq2.Shops.Shipping

    @valid_attrs %{
      name: "Anywhere",
      price: "10.00"
    }
    @invalid_attrs %{
      name: nil,
      price: nil
    }

    setup [:default_account]

    test "changeset with valid attributes", %{account: account} do
      changeset = Shipping.changeset(%Shipping{}, @valid_attrs, account)

      assert changeset.valid?
    end

    test "changeset with invalid attributes", %{account: account} do
      changeset = Shipping.changeset(%Shipping{}, @invalid_attrs, account)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:name, "")
        |> Map.put(:price, "")

      changeset = Shipping.changeset(%Shipping{}, attrs, account)

      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).price
    end

    test "changeset does not accept negative money attributes", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:price, Money.new(-1, :ARS))

      changeset = Shipping.changeset(%Shipping{}, attrs, account)

      assert "must be greater than or equal to 0" in errors_on(changeset).price
    end
  end
end
