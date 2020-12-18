defmodule Tq2.Transactions.CartTest do
  use Tq2.DataCase, async: true

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
  end

  defp default_account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end
