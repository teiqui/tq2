defmodule Tq2.Payments.LicensePaymentRepoTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [default_account: 0]

  describe "license_payment" do
    alias Tq2.Payments.LicensePayment, as: LPayment

    @valid_attrs %{
      amount: Money.new(20000, :ARS),
      external_id: Ecto.UUID.generate(),
      status: "paid",
      paid_at: Timex.now()
    }

    defp payment_fixture(account, attrs \\ %{}) do
      payment_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, payment} = Tq2.Payments.create_or_update_license_payment(payment_attrs, account)

      payment
    end

    test "converts unique constraint on external_id to error" do
      account = default_account()
      payment = payment_fixture(account)
      attrs = Map.put(@valid_attrs, :external_id, payment.external_id)
      changeset = LPayment.changeset(account, %LPayment{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:external_id]]
      }

      assert expected == changeset.errors[:external_id]
    end
  end
end
