defmodule Tq2.Workers.LicensesJobTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [create_session: 0, user_fixture: 1]

  alias Tq2.Accounts
  alias Tq2.Workers.LicensesJob
  alias Tq2.Notifications.Email

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

    test "perform notify near to expire license" do
      license = license()
      user = create_session() |> user_fixture()

      LicensesJob.perform("notify_near_to_expire", license.id)
      email = Email.license_near_to_expire(user)
      job = Exq.Mock.jobs() |> List.first()

      assert job.class == Tq2.Workers.MailerJob
      assert List.first(job.args).private == email.private
    end

    test "perform lock license" do
      license = license()
      user = create_session() |> user_fixture()

      LicensesJob.perform("lock", license.id)

      email = Email.license_expired(user)
      job = Exq.Mock.jobs() |> List.first()

      assert job.class == Tq2.Workers.MailerJob
      assert List.first(job.args).private == email.private

      assert Accounts.get_account!(license.account_id).status == "locked"
      assert Accounts.get_license!(license.account).status == "locked"
    end
  end

  defp mock do
    [retrieve: fn id -> {:ok, %{id: id, status: "unpaid"}} end]
  end

  defp license do
    %{account: %{license: license} = account} = create_session()

    {:ok, license} =
      Accounts.update_license(
        license,
        %{customer_id: "cus_123", subscription_id: "sub_123"}
      )

    %{license | account: account}
  end
end
