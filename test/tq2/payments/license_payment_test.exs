defmodule Tq2.Payments.LicensePaymentTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [default_account: 0]

  describe "license_payments" do
    alias Tq2.Payments.LicensePayment, as: LPayment

    @valid_attrs %{
      amount: Money.new(20000, :ARS),
      external_id: Ecto.UUID.generate(),
      status: "paid",
      paid_at: Timex.now()
    }

    @invalid_attrs %{
      amount: nil,
      external_id: nil,
      status: nil,
      paid_at: nil
    }

    test "changeset with valid attributes" do
      changeset = changeset_for_attrs(@valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = changeset_for_attrs(@invalid_attrs)

      refute changeset.valid?
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
        |> changeset_for_attrs()

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset does not accept negative money attributes" do
      changeset =
        @valid_attrs
        |> Map.put(:amount, Money.new(-1, :ARS))
        |> changeset_for_attrs()

      assert "must be greater than or equal to 0" in errors_on(changeset).amount
    end

    defp changeset_for_attrs(attrs) do
      default_account()
      |> LPayment.changeset(%LPayment{}, attrs)
    end
  end
end
