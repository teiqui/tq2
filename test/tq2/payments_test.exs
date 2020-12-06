defmodule Tq2.PaymentsTest do
  use Tq2.DataCase

  import Ecto.Query

  alias Tq2.Payments

  describe "license_payments" do
    setup [:default_account]

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

    defp default_account(_) do
      account =
        Tq2.Accounts.Account
        |> where(name: "test_account")
        |> join(:left, [a], l in assoc(a, :license))
        |> preload([a, l], license: l)
        |> Tq2.Repo.one()

      {:ok, account: account}
    end

    defp payment_fixture(account, attrs \\ %{}) do
      payment_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, payment} = Payments.create_or_update_license_payment(payment_attrs, account)

      payment
    end

    test "list_license_recent_payments/2 returns all license_payments", %{account: account} do
      payment = payment_fixture(account)

      assert Payments.list_recent_license_payments(account) == [payment]
    end

    test "create_or_update_license_payment/2 with valid data creates a payment", %{
      account: account
    } do
      assert {:ok, %LPayment{} = payment} =
               Payments.create_or_update_license_payment(@valid_attrs, account)

      assert payment.amount == @valid_attrs.amount
      assert payment.paid_at == @valid_attrs.paid_at
      assert payment.external_id == @valid_attrs.external_id
      assert payment.status == @valid_attrs.status
    end

    test "create_or_update_license_payment/2 with valid data updates a payment", %{
      account: account
    } do
      payment = payment_fixture(account)

      attrs =
        @valid_attrs
        |> Map.put(:external_id, payment.external_id)
        |> Map.put(:status, "pending")

      assert {:ok, %LPayment{} = same_payment} =
               Payments.create_or_update_license_payment(attrs, account)

      assert same_payment.id == payment.id
      assert same_payment.status == "pending"
      assert same_payment.amount == @valid_attrs.amount
      assert same_payment.paid_at == @valid_attrs.paid_at
      assert same_payment.external_id == @valid_attrs.external_id
    end

    test "create_or_update_license_payment/2 with valid data without new versions", %{
      account: account
    } do
      payment = payment_fixture(account)
      versions = versions_for_payment(payment)

      attrs = @valid_attrs |> Map.put(:external_id, payment.external_id)

      assert {:ok, %LPayment{} = same_payment} =
               Payments.create_or_update_license_payment(attrs, account)

      assert same_payment.id == payment.id
      assert same_payment.status == @valid_attrs.status
      assert same_payment.amount == @valid_attrs.amount
      assert same_payment.paid_at == @valid_attrs.paid_at
      assert same_payment.external_id == @valid_attrs.external_id
      assert versions_for_payment(payment) == versions
    end

    test "create_or_update_license_payment/2 with invalid_data", %{account: account} do
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
