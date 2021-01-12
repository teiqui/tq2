defmodule Tq2.Workers.LicensesJobTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [default_account: 0]

  alias Tq2.Accounts
  alias Tq2.Workers.LicensesJob

  describe "license job" do
    test "perform with customer_id" do
      license = license()

      with_mock Stripe.Subscription, mock() do
        assert updated_license = LicensesJob.perform("customer_id", license.customer_id)

        assert updated_license.subscription_id == license.subscription_id
        assert updated_license.status == "locked"
        assert updated_license.paid_until == license.paid_until
      end
    end

    test "perform with subscription_id" do
      license = license()

      with_mock Stripe.Subscription, mock() do
        assert updated_license = LicensesJob.perform("subscription_id", license.subscription_id)

        assert updated_license.subscription_id == license.subscription_id
        assert updated_license.status == "locked"
        assert updated_license.paid_until == license.paid_until
      end
    end
  end

  defp mock do
    [retrieve: fn id -> {:ok, %{id: id, status: "unpaid"}} end]
  end

  defp license do
    account = default_account()

    {:ok, license} =
      Accounts.update_license(
        account.license,
        %{customer_id: "cus_123", subscription_id: "sub_123"}
      )

    %{license | account: account}
  end
end
