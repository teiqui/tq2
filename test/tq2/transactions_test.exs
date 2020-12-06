defmodule Tq2.TransactionsTest do
  use Tq2.DataCase

  alias Tq2.Transactions

  describe "carts" do
    alias Tq2.Transactions.Cart

    @valid_attrs %{}
    @update_attrs %{}

    test "get_cart!/2 returns the cart with given id" do
      account = account()
      cart = fixture(account, :cart)

      assert Transactions.get_cart!(account, cart.id) == cart
    end

    test "create_cart/2 with valid data creates a cart" do
      assert {:ok, %Cart{}} = account() |> Transactions.create_cart(@valid_attrs)
    end

    test "update_cart/3 with valid data updates the cart" do
      account = account()
      cart = fixture(account, :cart)

      assert {:ok, cart} = Transactions.update_cart(account, cart, @update_attrs)
      assert %Cart{} = cart
    end

    test "change_cart/2 returns a cart changeset" do
      account = account()
      cart = fixture(account, :cart)

      assert %Ecto.Changeset{} = Transactions.change_cart(account, cart)
    end
  end

  describe "lines" do
    setup [:create_cart]

    alias Tq2.Transactions.{Cart, Line}

    @valid_attrs %{
      name: "some name",
      quantity: 42,
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      cost: Money.new(80, :ARS),
      item: %{
        sku: "some sku",
        name: "some name",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS)
      }
    }
    @update_attrs %{
      name: "some updated name",
      quantity: 43,
      price: Money.new(110, :ARS),
      promotional_price: Money.new(100, :ARS),
      cost: Money.new(90, :ARS),
      item: %{
        sku: "some updated sku",
        name: "some updated name",
        description: "some updated description",
        visibility: "hidden",
        # They are the same as create on purpose
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS)
      }
    }
    @invalid_attrs %{
      name: nil,
      quantity: nil,
      price: nil,
      promotional_price: nil,
      cost: nil,
      item: nil
    }

    defp create_cart(_) do
      account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
      {:ok, cart} = Transactions.create_cart(account, %{})

      {:ok, cart: cart}
    end

    test "get_line!/2 returns the line with given id", %{cart: cart} do
      line = fixture(cart, :line)

      assert Transactions.get_line!(cart, line.id).id == line.id
    end

    test "create_line/2 with valid data creates a line", %{cart: cart} do
      item = account() |> fixture(:item, %{})

      assert {:ok, %Line{} = line} = Transactions.create_line(cart, %{@valid_attrs | item: item})
      assert line.name == @valid_attrs.name
      assert line.quantity == @valid_attrs.quantity
      assert line.price == @valid_attrs.price
      assert line.promotional_price == @valid_attrs.promotional_price
      assert line.cost == @valid_attrs.cost
    end

    test "create_line/2 with invalid data returns error changeset", %{cart: cart} do
      assert {:error, %Ecto.Changeset{}} = Transactions.create_line(cart, @invalid_attrs)
    end

    test "update_line/3 with valid data updates the line", %{cart: cart} do
      line = fixture(cart, :line)

      assert {:ok, line} = Transactions.update_line(cart, line, @update_attrs)
      assert %Line{} = line
      # Only quantity can be updated
      assert line.quantity == @update_attrs.quantity
      refute line.name == @update_attrs.name
      refute line.price == @update_attrs.price
      refute line.promotional_price == @update_attrs.promotional_price
      refute line.cost == @update_attrs.cost
    end

    test "update_line/3 with invalid data returns error changeset", %{cart: cart} do
      line = fixture(cart, :line)

      assert {:error, %Ecto.Changeset{}} = Transactions.update_line(cart, line, @invalid_attrs)
      assert line.name == Transactions.get_line!(cart, line.id).name
    end

    test "delete_line/1 deletes the line", %{cart: cart} do
      line = fixture(cart, :line)

      assert {:ok, %Line{}} = Transactions.delete_line(line)
      assert_raise Ecto.NoResultsError, fn -> Transactions.get_line!(cart, line.id) end
    end

    test "change_line/2 returns a line changeset", %{cart: cart} do
      line = fixture(cart, :line)

      assert %Ecto.Changeset{} = Transactions.change_line(cart, line)
    end
  end

  defp fixture(account, kind, attrs \\ %{})

  defp fixture(account, :cart, attrs) do
    cart_attrs = Enum.into(attrs, @valid_attrs)

    {:ok, cart} = Transactions.create_cart(account, cart_attrs)

    cart
  end

  defp fixture(account, :item, attrs) do
    session = %Tq2.Accounts.Session{account: account}
    item_attrs = Enum.into(attrs, @valid_attrs[:item])
    {:ok, item} = Tq2.Inventories.create_item(session, item_attrs)

    item
  end

  defp fixture(cart, :line, attrs) do
    line_attrs = Enum.into(attrs, @valid_attrs)
    item = account() |> fixture(:item, line_attrs[:item])
    {:ok, line} = Transactions.create_line(cart, %{line_attrs | item: item})

    line
  end

  defp account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end