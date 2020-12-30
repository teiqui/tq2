defmodule Tq2.Payments.PaymentRepoTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [default_account: 0]

  describe "payment" do
    alias Tq2.Payments.Payment

    @valid_attrs %{
      amount: Money.new(20000, :ARS),
      status: "paid",
      kind: "cash",
      external_id: Ecto.UUID.generate()
    }

    @valid_cart_attrs %{
      token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoM="
    }

    defp payment_fixture(attrs \\ %{}) do
      line = %Tq2.Transactions.Line{price: Money.new(2000, "ARS")}

      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(@valid_cart_attrs)

      cart = %{cart | lines: [line]}

      payment_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, payment} = cart |> Tq2.Payments.create_payment(payment_attrs)

      %{payment | cart: cart}
    end

    test "converts unique constraint on external_id to error" do
      payment = payment_fixture()
      attrs = Map.put(@valid_attrs, :external_id, payment.external_id)
      changeset = Payment.changeset(payment.cart, %Payment{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:external_id]]
      }

      assert expected == changeset.errors[:external_id]
    end
  end
end
