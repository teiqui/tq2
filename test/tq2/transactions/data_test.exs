defmodule Tq2.Transactions.DataTest do
  use Tq2.DataCase, async: true

  describe "data" do
    alias Tq2.Transactions.Data

    @valid_attrs %{
      handing: "pickup",
      payment: "cash"
    }
    @invalid_attrs %{
      handing: "wrong",
      payment: "wrong"
    }

    test "changeset with valid attributes" do
      changeset = Data.changeset(%Data{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Data.changeset(%Data{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:handing, "xx")
        |> Map.put(:payment, "xx")

      changeset = Data.changeset(%Data{}, attrs)

      assert "is invalid" in errors_on(changeset).handing
      assert "is invalid" in errors_on(changeset).payment
    end

    test "changeset require shipping with delivery" do
      attrs =
        @valid_attrs
        |> Map.put(:handing, "delivery")
        |> Map.put(:shipping, nil)

      changeset = Data.changeset(%Data{}, attrs)

      assert "can't be blank" in errors_on(changeset).shipping
    end

    test "from_struct/1 returns a valid non-struct map" do
      map = Map.from_struct(%Data{})

      assert ^map = Data.from_struct(nil)
      assert ^map = Data.from_struct(%Data{})

      shipping = %Tq2.Shops.Shipping{
        name: "Anywhere",
        price: %Money{amount: 1000, currency: :ARS}
      }

      map = Map.put(map, :shipping, Map.from_struct(shipping))

      assert ^map = Data.from_struct(%Data{shipping: shipping})
    end
  end
end
