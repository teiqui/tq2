defmodule Tq2.Accounts.LicenseTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [default_account: 0]

  describe "license" do
    alias Tq2.Accounts.License
    alias Tq2.Payments.LicensePayment, as: LPayment

    @valid_attrs %{
      status: "trial",
      reference: Ecto.UUID.generate()
    }
    @invalid_attrs %{
      status: "unknown",
      reference: "123"
    }

    test "changeset with valid attributes" do
      changeset = License.changeset(%License{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = License.changeset(%License{}, @invalid_attrs)

      refute changeset.valid?

      assert "is invalid" in errors_on(changeset).status
      assert "is invalid" in errors_on(changeset).reference
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:status, String.duplicate("a", 256))

      changeset = License.changeset(%License{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).status
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:status, "xx")

      changeset = License.changeset(%License{}, attrs)

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset for payment with active status" do
      account = default_account()
      next_month = account.license.paid_until |> Timex.shift(months: 1)
      payment_cs = account |> LPayment.changeset(%LPayment{}, %{status: "paid"})
      license_cs = account.license |> License.put_paid_until_changes(payment_cs)

      assert license_cs.changes.status == "active"
      assert license_cs.changes.paid_until == next_month
    end

    test "changeset for payment with unpaid status" do
      account = default_account()
      prev_month = account.license.paid_until |> Timex.shift(months: -1)
      payment_cs = account |> LPayment.changeset(%LPayment{}, %{status: "cancelled"})
      license_cs = account.license |> License.put_paid_until_changes(payment_cs)

      assert license_cs.changes.status == "unpaid"
      assert license_cs.changes.paid_until == prev_month
    end

    test "changeset for payment without status change" do
      account = default_account()
      payment_cs = account |> LPayment.changeset(%LPayment{}, %{status: "pending"})
      license_cs = account.license |> License.put_paid_until_changes(payment_cs)

      refute license_cs.changes[:status]
      refute license_cs.changes[:paid_until]
    end

    test "add changeset to multi" do
      account = default_account()
      multi = Ecto.Multi.new()

      multi =
        account.license
        |> License.changeset(%{})
        |> License.add_changeset_to_multi(multi)
        |> Ecto.Multi.to_list()

      assert {:update, _, []} = multi[:license]
      assert {:run, _} = multi[:license_version]
    end
  end
end
