defmodule Tq2.Gateways.Stripe do
  import Tq2.Utils.Urls, only: [app_uri: 0, store_uri: 0]

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, License}

  @monthly_plans %{
    "ar" => "price_1I8vJ6LvW6Kv2wj4gr5At51o",
    "cl" => "price_1I8vJ6LvW6Kv2wj43vANfj99",
    "co" => "price_1I8vJ6LvW6Kv2wj4wjsTOzjT",
    "mx" => "price_1I7OdaLvW6Kv2wj4gNVRgeaW",
    "pe" => "price_1I8vJ6LvW6Kv2wj4LlziLyet",
    "us" => "price_1I8vJ6LvW6Kv2wj4HfFPfDfS"
  }
  @yearly_plans %{
    "ar" => "price_1I8vBqLvW6Kv2wj49azo23X1",
    "cl" => "price_1I8vBrLvW6Kv2wj4Cs2nK4Ez",
    "co" => "price_1I8vBrLvW6Kv2wj4fPSlDJU7",
    "mx" => "price_1I7OhJLvW6Kv2wj4fjGkQO9I",
    "pe" => "price_1I8vBqLvW6Kv2wj4wvL0aqyd",
    "us" => "price_1I8vBrLvW6Kv2wj4iKScWZEd"
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
        time_zone: account.time_zone,
        store: store_url(account)
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

  def create_subscription_session(%License{} = license, period \\ :monthly) do
    session_params = session_params(license, period)

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
    case Stripe.Subscription.retrieve(id) do
      {:ok, subscription} -> subscription
      _ -> nil
    end
  end

  def find_subscription(%License{customer_id: id}) do
    case Stripe.Customer.retrieve(id) do
      {:ok, %{subscriptions: %{data: subscriptions}}} ->
        subscriptions
        |> Enum.filter(&(&1.status != "canceled"))
        |> List.first()

      _ ->
        nil
    end
  end

  def update_license(%License{} = license) do
    attrs =
      license
      |> find_subscription()
      |> subscription_to_license_attrs()

    update_license_status(license, attrs)
  end

  defp update_license_status(%{account: account} = license, %{status: status} = attrs) do
    account_status = if status in ["canceled", "locked"], do: "locked", else: "active"

    Ecto.Multi.new()
    |> Ecto.Multi.update(:account, Account.changeset(account, %{status: account_status}))
    |> Ecto.Multi.update(:license, License.changeset(license, attrs))
    |> commit_update()
  end

  defp commit_update(multi) do
    case Tq2.Repo.transaction(multi) do
      {:ok, %{account: account, license: license}} ->
        %{license | account: account}

      {:error, _operation, failed_value, changes} ->
        license_error_to_sentry(failed_value, changes)

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
    if System.get_env("MOCK_STRIPE") do
      "price_1I3qfnLvW6Kv2wj4yDzztvYo"
    else
      @monthly_plans[country] || @monthly_plans[@default_price]
    end
  end

  defp price_id(%{country: country}, :yearly) do
    if System.get_env("MOCK_STRIPE") do
      "price_1I8brELvW6Kv2wj4UC4sDVCD"
    else
      @yearly_plans[country] || @yearly_plans[@default_price]
    end
  end

  defp subscription_to_license_attrs(%{current_period_end: ts, id: id, status: status})
       when status in ["trialing", "active"] do
    %{
      status: @statuses_for_license[status],
      subscription_id: id,
      paid_until: DateTime.from_unix!(ts)
    }
  end

  defp subscription_to_license_attrs(%{status: "canceled"}) do
    %{
      status: @statuses_for_license["canceled"],
      subscription_id: nil
    }
  end

  defp subscription_to_license_attrs(%{id: id, status: status}) do
    %{
      status: @statuses_for_license[status],
      subscription_id: id
    }
  end

  defp session_params(
         %License{account: account, customer_id: customer_id, paid_until: paid_until},
         period
       ) do
    defaults = %{
      cancel_url: license_url(),
      success_url: license_url(),
      mode: "subscription",
      payment_method_types: ["card"],
      customer: customer_id,
      allow_promotion_codes: false,
      line_items: [
        %{quantity: 1, price: price_id(account, period)}
      ]
    }

    case trial_days(paid_until) do
      nil -> defaults
      n -> Map.put(defaults, :subscription_data, %{trial_period_days: n})
    end
  end

  defp trial_days(date) do
    case Timex.diff(date, Date.utc_today(), :days) do
      d when d > 0 -> d
      _ -> nil
    end
  end

  defp store_url(%Account{} = account) do
    store = Tq2.Shops.get_store!(account)

    store_uri()
    |> Tq2Web.Router.Helpers.counter_url(:index, store)
  end
end
