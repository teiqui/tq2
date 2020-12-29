defmodule Tq2.PaymentsTest do
  use Tq2.DataCase, async: true

  import Ecto.Query
  import Tq2.Fixtures, only: [create_session: 1]

  alias Tq2.Accounts
  alias Tq2.Payments

  describe "license_payments" do
    setup [:create_session]

    alias Tq2.Payments.LicensePayment, as: LPayment

    @valid_attrs %{
      external_id: Ecto.UUID.generate(),
      amount: Money.new(20000, :ARS),
      paid_at: DateTime.truncate(Timex.now(), :second),
      status: "paid"
    }
    @invalid_attrs %{
      amount: nil,
      paid_at: nil,
      external_id: nil,
      status: nil
    }

    defp payment_fixture(account, attrs \\ %{}) do
      payment_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, payment} = Payments.create_or_update_license_payment(payment_attrs, account)

      payment
    end

    test "list_license_recent_payments/2 returns all license_payments", %{
      session: %{account: account}
    } do
      payment = payment_fixture(account)

      listed_payment =
        account
        |> Payments.list_recent_license_payments()
        |> List.first()

      assert listed_payment.id == payment.id
    end

    test "create_or_update_license_payment/2 with valid data creates a payment", %{
      session: session
    } do
      account = session.account

      {:ok, original_license} =
        session
        |> Accounts.update_license(account.license, %{status: "unpaid"})

      # Skip Stale object error
      account = %{account | license: original_license}

      assert {:ok, %LPayment{} = payment} =
               Payments.create_or_update_license_payment(@valid_attrs, account)

      license = Accounts.get_license!(account)
      paid_until = original_license.paid_until |> Timex.shift(months: 1)

      assert payment.amount == @valid_attrs.amount
      assert payment.paid_at == @valid_attrs.paid_at
      assert payment.external_id == @valid_attrs.external_id
      assert payment.status == @valid_attrs.status
      assert license.status == "active"
      assert license.paid_until == paid_until
    end

    test "create_or_update_license_payment/2 with valid data updates a payment", %{
      session: %{account: account}
    } do
      payment = payment_fixture(account)
      original_license = payment.license

      attrs =
        @valid_attrs
        |> Map.put(:external_id, payment.external_id)
        |> Map.put(:status, "pending")

      assert {:ok, %LPayment{} = same_payment} =
               Payments.create_or_update_license_payment(attrs, account)

      license = Accounts.get_license!(account)

      assert same_payment.id == payment.id
      assert same_payment.status == "pending"
      assert same_payment.amount == @valid_attrs.amount
      assert same_payment.paid_at == @valid_attrs.paid_at
      assert same_payment.external_id == @valid_attrs.external_id
      assert original_license.status == license.status
      assert original_license.paid_until == license.paid_until
    end

    test "create_or_update_license_payment/2 with valid data without new versions", %{
      session: %{account: account}
    } do
      payment = payment_fixture(account)
      versions = versions_for_payment(payment)
      original_license = payment.license

      attrs = @valid_attrs |> Map.put(:external_id, payment.external_id)

      assert {:ok, %LPayment{} = same_payment} =
               Payments.create_or_update_license_payment(attrs, account)

      license = Accounts.get_license!(account)

      assert same_payment.id == payment.id
      assert same_payment.status == @valid_attrs.status
      assert same_payment.amount == @valid_attrs.amount
      assert same_payment.paid_at == @valid_attrs.paid_at
      assert same_payment.external_id == @valid_attrs.external_id
      assert versions_for_payment(payment) == versions
      assert original_license.status == license.status
      assert original_license.paid_until == license.paid_until
    end

    test "create_or_update_license_payment/2 with invalid_data", %{session: %{account: account}} do
      assert nil == Payments.create_or_update_license_payment(@invalid_attrs, account)
    end

    defp versions_for_payment(payment) do
      PaperTrail.Version
      |> where(item_id: ^payment.id, item_type: "LicensePayment")
      |> select([v], count(v.id))
      |> Tq2.Repo.one()
    end
  end

  describe "payments" do
    setup [:create_session]

    alias Tq2.Payments.Payment

    @valid_attrs %{
      amount: Money.new(2000, "ARS"),
      kind: "cash",
      status: "paid"
    }
    @invalid_attrs %{
      amount: nil,
      kind: nil,
      status: nil
    }
    @valid_cart_attrs %{
      token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoM="
    }
    @mp_attrs %{
      amount: Money.new(2000, "ARS"),
      status: "pending",
      external_id: "tq2-mp-cart-123",
      kind: "mercado_pago"
    }

    defp cart_fixture(account) do
      {:ok, cart} = account |> Tq2.Transactions.create_cart(@valid_cart_attrs)

      cart
    end

    defp order_fixture(account, cart) do
      {:ok, order} =
        Tq2.Sales.create_order(
          account,
          %{
            cart_id: cart.id,
            promotion_expires_at: DateTime.utc_now(),
            data: %{}
          }
        )

      %{order | cart: cart}
    end

    test "create_payment/2 with valid data creates a payment", %{session: %{account: account}} do
      assert {:ok, %Payment{} = payment} =
               account
               |> cart_fixture()
               |> Payments.create_payment(@valid_attrs)

      assert payment.amount == @valid_attrs.amount
      assert payment.kind == @valid_attrs.kind
      assert payment.status == @valid_attrs.status
    end

    test "create_payment/2 with invalid data returns error changeset", %{
      session: %{account: account}
    } do
      assert {:error, %Ecto.Changeset{}} =
               account
               |> cart_fixture()
               |> Payments.create_payment(@invalid_attrs)
    end

    test "update_payment/2 with valid data update payment create order", %{
      session: %{account: account}
    } do
      assert {:ok, %Payment{} = original_payment} =
               account
               |> cart_fixture()
               |> Payments.create_payment(@mp_attrs)

      original_payment = Tq2.Repo.preload(original_payment, :order, force: true)

      refute original_payment.order

      assert {:ok, payment} =
               Payments.update_payment(
                 %{
                   external_id: @mp_attrs.external_id,
                   status: "paid"
                 },
                 account
               )

      assert payment.status == "paid"
      assert payment.order.id
      assert payment.order.data.paid
    end

    test "update_payment/2 with valid data update payment with order", %{
      session: %{account: account}
    } do
      cart = account |> cart_fixture()

      assert {:ok, %Payment{} = original_payment} = cart |> Payments.create_payment(@mp_attrs)

      assert order_fixture(account, cart)

      original_payment = Tq2.Repo.preload(original_payment, :order, force: true)

      assert original_payment.order
      refute original_payment.order.data.paid

      assert {:ok, payment} =
               Payments.update_payment(
                 %{
                   external_id: @mp_attrs.external_id,
                   status: "paid"
                 },
                 account
               )

      assert payment.status == "paid"
      assert payment.order.id == original_payment.order.id
      assert payment.order.data.paid
    end
  end
end
