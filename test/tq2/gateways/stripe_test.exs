defmodule Tq2.Gateways.StripeTest do
  use Tq2.DataCase

  import Mock

  import Tq2.Fixtures, only: [create_session: 1, user_fixture: 1]

  alias Tq2.Gateways.Stripe, as: StripeClient

  describe "stripe" do
    @default_customer %{
      id: "cus_123"
    }

    setup [:create_session, :create_owner]

    test "create_customer/1 returns updated license", %{session: %{account: %{license: license}}} do
      refute license.customer_id

      mock = [create: fn _attrs -> {:ok, @default_customer} end]

      with_mock Stripe.Customer, mock do
        updated_license = StripeClient.create_customer(license)

        assert updated_license.customer_id
      end
    end

    test "create_customer/1 with error returns same license", %{
      session: %{account: %{license: license}}
    } do
      refute license.customer_id

      mock = [create: fn _attrs -> {:error, "error"} end]

      with_mock Stripe.Customer, mock do
        same_license = StripeClient.create_customer(license)

        refute same_license.customer_id
      end
    end

    test "create_subscription_session/1 returns session id", %{
      session: %{account: %{license: license}}
    } do
      license = %{license | customer_id: @default_customer.id}

      mock = [create: fn _attrs -> {:ok, %{id: "cs_123"}} end]

      with_mock Stripe.Session, mock do
        assert {:ok, "cs_123"} = StripeClient.create_subscription_session(license)
      end
    end

    test "create_subscription_session/1 internal params select correct price", %{
      session: %{account: %{license: license} = account}
    } do
      license = %{license | customer_id: @default_customer.id}

      mock = [create: fn attrs -> {:ok, %{id: attrs}} end]

      with_mock Stripe.Session, mock do
        assert {:ok, attrs} = StripeClient.create_subscription_session(license)

        # Monthly AR price
        assert List.first(attrs.line_items).price == "price_1I3qdWLvW6Kv2wj42WHC5QSd"

        license = %{license | account: %{account | country: "xx"}}

        # Monthly US price
        assert {:ok, attrs} = StripeClient.create_subscription_session(license)

        assert List.first(attrs.line_items).price == "price_1I0ybqLvW6Kv2wj4bU6tIYQz"

        # Yearly US price
        assert {:ok, attrs} = StripeClient.create_subscription_session(license, :yearly)

        assert List.first(attrs.line_items).price == "price_1I7OfCLvW6Kv2wj4fVGvNRwG"
      end
    end

    test "create_billing_session/1 returns an url", %{session: %{account: %{license: license}}} do
      license = %{license | customer_id: "cus_123"}

      url = "https://valid.url"
      mock = [create: fn _attrs -> {:ok, %{url: url}} end]

      with_mock Stripe.BillingPortal.Session, mock do
        assert {:ok, session_url} = StripeClient.create_billing_session(license)
        assert session_url == url
      end
    end

    test "find_subscription/1 returns a subscription", %{session: %{account: %{license: license}}} do
      license = %{license | subscription_id: "sub_123"}

      mock = [
        retrieve: fn id ->
          {:ok,
           %{id: id, status: "active", current_period_end: System.os_time(:second)}}
        end
      ]

      with_mock Stripe.Subscription, mock do
        assert subscription = StripeClient.find_subscription(license)
        assert subscription.id == license.subscription_id
        assert subscription.status == "active"
      end
    end

    test "find_subscription/1 returns a subscription for customer", %{
      session: %{account: %{license: license}}
    } do
      license = %{license | customer_id: "cus_123"}

      customer = %{
        id: license.customer_id,
        subscriptions: %{data: [%{id: "sub_123", status: "active"}]}
      }

      mock = [retrieve: fn _id -> {:ok, customer} end]

      with_mock Stripe.Customer, mock do
        assert subscription = StripeClient.find_subscription(license)
        assert subscription.id
        assert subscription.status == "active"
      end
    end

    test "updated_license/1 returns an updated license", %{
      session: %{account: %{license: license}}
    } do
      license = %{license | subscription_id: "sub_123"}

      mock = [retrieve: fn id -> {:ok, %{id: id, status: "unpaid"}} end]

      with_mock Stripe.Subscription, mock do
        assert updated_license = StripeClient.update_license(license)

        assert updated_license.subscription_id == license.subscription_id
        assert updated_license.status == "locked"
      end
    end
  end

  defp create_owner(%{session: session}), do: %{owner: user_fixture(session)}
end
