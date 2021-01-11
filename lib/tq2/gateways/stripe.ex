defmodule Tq2.Gateways.Stripe do
  import Tq2.Utils.Urls, only: [app_uri: 0]

  alias Tq2.Accounts
  alias Tq2.Accounts.License

  @monthly_plans %{
    "ar" => "price_1I3qdWLvW6Kv2wj42WHC5QSd",
    "cl" => "price_1I7Ob0LvW6Kv2wj41z16zLdK",
    "co" => "price_1I7OcQLvW6Kv2wj4rCWdoCQF",
    "mx" => "price_1I7OdaLvW6Kv2wj4gNVRgeaW",
    "pe" => "price_1I7OdILvW6Kv2wj4UaYeNGUg",
    "us" => "price_1I0ybqLvW6Kv2wj4bU6tIYQz"
  }
  @yearly_plans %{
    "ar" => "price_1I7OfcLvW6Kv2wj4quCztx47",
    "cl" => "price_1I7OgQLvW6Kv2wj4KojYs8CE",
    "co" => "price_1I7Og1LvW6Kv2wj4hSoMiyC2",
    "mx" => "price_1I7OhJLvW6Kv2wj4fjGkQO9I",
    "pe" => "price_1I7OgtLvW6Kv2wj4xlegNB3V",
    "us" => "price_1I7OfCLvW6Kv2wj4fVGvNRwG"
  }
  @default_price "us"

  @statuses_for_license %{
    "trialing" => "active",
    "active" => "active",
    "past_due" => "unpaid",
    "incomplete" => "unpaid",
    "incomplete_expired" => "unpaid",
    "unpaid" => "locked",
    "canceled" => "canceled"
  }

  def create_customer(%License{account: account} = license) do
    owner = Accounts.get_owner(account)

    attrs = %{
      name: account.name,
      email: owner.email,
      metadata: %{
        account_id: account.id,
        country: account.country,
        time_zone: account.time_zone
      }
    }

    case Stripe.Customer.create(attrs) do
      {:ok, customer} ->
        update_license_with_customer(license, customer)

      {:error, response} ->
        Sentry.capture_message("[Stripe] Can't create customer",
          extra: %{license_id: license.id, owner_id: owner.id, response: inspect(response)}
        )

        license
    end
  end

  def create_subscription_session(
        %License{account: account, customer_id: customer_id},
        period \\ :monthly
      ) do
    session_params = %{
      cancel_url: license_url(),
      success_url: license_url(),
      mode: "subscription",
      payment_method_types: ["card"],
      customer: customer_id,
      line_items: [
        %{quantity: 1, price: price_id(account, period)}
      ]
    }

    case Stripe.Session.create(session_params) do
      {:ok, session} -> {:ok, session.id}
      {:error, %{message: error}} -> {:error, error}
    end
  end

  def create_billing_session(%License{customer_id: customer_id}) do
    case Stripe.BillingPortal.Session.create(%{customer: customer_id}) do
      {:ok, %{url: url}} -> {:ok, url}
      {:error, %{message: message}} -> {:error, message}
    end
  end

  def find_subscription(%License{subscription_id: id}) when not is_nil(id) do
    {:ok, subscription} = Stripe.Subscription.retrieve(id)

    subscription
  end

  def find_subscription(%License{customer_id: id}) do
    {:ok, %{subscriptions: %{data: subscriptions}}} = Stripe.Customer.retrieve(id)

    subscriptions
    |> Enum.filter(&(&1.status != "canceled"))
    |> List.first()
  end

  def update_license(%License{account: account} = license) do
    attrs =
      license
      |> find_subscription()
      |> subscription_to_license_attrs()

    case Accounts.update_license(license, attrs) do
      {:ok, license} ->
        %{license | account: account}

      {:error, changeset} ->
        license_error_to_sentry(changeset, attrs)

        nil
    end
  end

  defp update_license_with_customer(license, customer) do
    attrs = %{customer_id: customer.id}

    case Accounts.update_license(license, attrs) do
      {:ok, updated_license} ->
        %{updated_license | account: license.account}

      {:error, changeset} ->
        license_error_to_sentry(changeset, attrs)
        license
    end
  end

  defp license_error_to_sentry(%Ecto.Changeset{data: %{id: id}, errors: errors}, attrs) do
    Sentry.capture_message(
      "[Stripe] Can't update license",
      extra: %{license_id: id, errors: inspect(errors), attrs: inspect(attrs)}
    )
  end

  defp license_url do
    app_uri() |> Tq2Web.Router.Helpers.license_url(:index)
  end

  defp price_id(%{country: country}, :monthly) do
    @monthly_plans[country] || @monthly_plans[@default_price]
  end

  defp price_id(%{country: country}, :yearly) do
    @yearly_plans[country] || @yearly_plans[@default_price]
  end

  defp subscription_to_license_attrs(%{id: id, status: status}) do
    %{status: @statuses_for_license[status], subscription_id: id}
  end
end
