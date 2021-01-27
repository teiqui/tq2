defmodule Tq2.Sales.OrderTest do
  use Tq2.DataCase, async: true

  describe "order" do
    alias Tq2.Sales.Order

    @valid_attrs %{
      status: "pending",
      promotion_expires_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    @invalid_attrs %{
      status: nil,
      promotion_expires_at: nil
    }

    test "changeset with valid attributes" do
      changeset = default_account() |> Order.changeset(%Order{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> Order.changeset(%Order{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:status, "invalid")

      changeset = default_account() |> Order.changeset(%Order{}, attrs)

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset check paid order on completion" do
      attrs =
        @valid_attrs
        |> Map.put(:status, "completed")

      changeset = default_account() |> Order.changeset(%Order{}, attrs)

      assert "To complete an order must be fully paid." in errors_on(changeset).status
    end
  end

  defp default_account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end
