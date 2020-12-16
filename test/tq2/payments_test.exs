defmodule Tq2.PaymentsTest do
  use Tq2.DataCase

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
end
