defmodule Tq2.Transactions.CartTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [default_account: 0, create_session: 0]

  describe "cart" do
    alias Tq2.Transactions.Cart

    @valid_attrs %{
      token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
      price_type: "promotional",
      account_id: "1"
    }
    @invalid_attrs %{
      token: nil,
      price_type: nil,
      account_id: nil
    }

    test "changeset with valid attributes" do
      changeset = Cart.changeset(%Cart{}, @valid_attrs, default_account())

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Cart.changeset(%Cart{}, @invalid_attrs, default_account())

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:token, String.duplicate("a", 256))

      changeset = Cart.changeset(%Cart{}, attrs, default_account())

      assert "should be at most 255 character(s)" in errors_on(changeset).token
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:price_type, "xx")

      changeset = Cart.changeset(%Cart{}, attrs, default_account())

      assert "is invalid" in errors_on(changeset).price_type
    end

    test "total for promotinal price" do
      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(@valid_attrs)

      cart = create_line(cart)

      assert Money.new(270, "ARS") == Cart.total(cart)
    end

    test "total for regular price" do
      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(%{@valid_attrs | price_type: "regular"})

      cart = create_line(cart)

      assert Money.new(300, "ARS") == Cart.total(cart)
    end
  end

  defp create_line(cart) do
    session = create_session()

    {:ok, item} =
      Tq2.Inventories.create_item(session, %{
        sku: "some sku",
        name: "some name",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS)
      })

    {:ok, _line} =
      Tq2.Transactions.create_line(cart, %{
        name: "some name",
        quantity: 3,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        item: item
      })

    Tq2.Repo.preload(cart, :lines, force: true)
  end
end
