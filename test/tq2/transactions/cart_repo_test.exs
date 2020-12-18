defmodule Tq2.Transactions.CartRepoTest do
  use Tq2.DataCase

  describe "cart" do
    alias Tq2.Accounts.Account
    alias Tq2.Transactions
    alias Tq2.Transactions.Cart

    @valid_attrs %{
      token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
      price_type: "promotional"
    }

    def cart_fixture(attrs \\ %{}) do
      account = Tq2.Repo.get_by!(Account, name: "test_account")

      cart_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, cart} = Transactions.create_cart(account, cart_attrs)

      %{cart | account: account}
    end

    test "converts unique constraint on token to error" do
      cart = cart_fixture(@valid_attrs)
      attrs = Map.put(@valid_attrs, :token, cart.token)

      {:error, changeset} =
        %Cart{}
        |> Cart.changeset(attrs, cart.account)
        |> Repo.insert()

      expected = {
        "has already been taken",
        [constraint: :unique, constraint_name: "carts_token_index"]
      }

      assert expected == changeset.errors[:token]
    end
  end
end
