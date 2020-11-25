defmodule Tq2.TransactionsTest do
  use Tq2.DataCase

  alias Tq2.Transactions

  describe "carts" do
    alias Tq2.Transactions.Cart

    @valid_attrs %{}
    @update_attrs %{}

    defp fixture(account, :cart, attrs \\ %{}) do
      cart_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, cart} = Transactions.create_cart(account, cart_attrs)

      cart
    end

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

  defp account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end
