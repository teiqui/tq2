defmodule Tq2.Payments.PaymentTest do
  use Tq2.DataCase, async: true

  describe "payments" do
    alias Tq2.Payments.Payment
    alias Tq2.Transactions.Cart

    @valid_attrs %{
      amount: Money.new(20000, :ARS),
      status: "paid",
      kind: "cash"
    }

    @invalid_attrs %{
      amount: nil,
      status: nil,
      kind: nil
    }

    test "changeset with valid attributes" do
      changeset = changeset_for_attrs(@valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = changeset_for_attrs(@invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept empty attributes" do
      changeset = @invalid_attrs |> changeset_for_attrs()

      assert "can't be blank" in errors_on(changeset).amount
      assert "can't be blank" in errors_on(changeset).kind
      assert "can't be blank" in errors_on(changeset).status
    end

    test "changeset does not accept long attributes" do
      changeset =
        @valid_attrs
        |> Map.put(:external_id, String.duplicate("a", 256))
        |> changeset_for_attrs()

      assert "should be at most 255 character(s)" in errors_on(changeset).external_id
    end

    test "changeset check inclusions" do
      changeset =
        @valid_attrs
        |> Map.put(:status, "xx")
        |> Map.put(:kind, "xx")
        |> changeset_for_attrs()

      assert "is invalid" in errors_on(changeset).status
      assert "is invalid" in errors_on(changeset).kind
    end

    test "changeset does not accept negative money attributes" do
      changeset =
        @valid_attrs
        |> Map.put(:amount, Money.new(-1, :ARS))
        |> changeset_for_attrs()

      assert "must be greater than or equal to 0" in errors_on(changeset).amount
    end

    defp changeset_for_attrs(attrs) do
      %Cart{} |> Payment.changeset(%Payment{}, attrs)
    end
  end
end
