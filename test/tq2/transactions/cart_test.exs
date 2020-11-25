defmodule Tq2.Transactions.CartTest do
  use Tq2.DataCase, async: true

  describe "cart" do
    alias Tq2.Transactions.Cart

    @valid_attrs %{
      account_id: "1"
    }

    test "changeset with valid attributes" do
      changeset = default_account() |> Cart.changeset(%Cart{}, @valid_attrs)

      assert changeset.valid?
    end
  end

  defp default_account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end
