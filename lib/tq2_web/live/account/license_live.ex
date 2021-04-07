defmodule Tq2Web.Account.LicenseLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils, only: [invert: 1, localize_date: 1]

  alias Tq2.Accounts
  alias Tq2.Accounts.License
  alias Tq2.Gateways.Stripe, as: StripeClient

  @statuses %{
    dgettext("licenses", "Trial") => "trial",
    dgettext("licenses", "Active") => "active",
    dgettext("licenses", "Unpaid") => "unpaid",
    dgettext("licenses", "Locked") => "locked",
    dgettext("licenses", "Canceled") => "canceled"
  }

  @impl true
  def mount(_, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)
    license = Accounts.get_license!(session.account)

    socket =
      socket
      |> assign(license: license, subscription: nil)
      |> trigger_fetch_subscription()

    {:ok, socket, temporary_assigns: [loading: false]}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> put_flash(:error, dgettext("sessions", "You must be logged in."))
      |> redirect(to: Routes.root_path(socket, :index))

    {:ok, socket}
  end

  @impl true
  def handle_event("monthly", _, socket) do
    socket = socket |> assign(loading: true)

    send(self(), {:monthly})

    {:noreply, socket}
  end

  @impl true
  def handle_event("yearly", _, socket) do
    socket = socket |> assign(loading: true)

    send(self(), {:yearly})

    {:noreply, socket}
  end

  @impl true
  def handle_event("customer-info", _, socket) do
    socket = socket |> assign(loading: true)

    send(self(), {:customer_info})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:monthly}, socket) do
    socket = socket |> create_monthly_session()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:yearly}, socket) do
    socket = socket |> create_yearly_session()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:fetch_subscription}, socket) do
    socket = socket |> fetch_subscription()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:customer_info}, socket) do
    socket = socket |> redirect_to_customer()

    {:noreply, socket}
  end

  defp create_monthly_session(%{assigns: %{license: %{customer_id: nil} = license}} = socket) do
    case StripeClient.create_customer(license) do
      %{customer_id: id} = license when is_binary(id) ->
        socket |> assign(license: license) |> create_monthly_session()

      _ ->
        socket |> put_flash(:error, dgettext("licenses", "Can't create subscription"))
    end
  end

  defp create_monthly_session(%{assigns: %{license: license}} = socket) do
    case StripeClient.create_subscription_session(license) do
      {:ok, id} ->
        socket
        |> assign(loading: true)
        |> push_event("redirect-to-checkout", %{id: id, key: public_key()})

      _ ->
        socket |> put_flash(:error, dgettext("licenses", "Can't create subscription"))
    end
  end

  defp create_yearly_session(%{assigns: %{license: %{customer_id: nil} = license}} = socket) do
    case StripeClient.create_customer(license) do
      %{customer_id: id} = license when is_binary(id) ->
        socket |> assign(license: license) |> create_yearly_session()

      _ ->
        socket |> put_flash(:error, dgettext("licenses", "Can't create subscription"))
    end
  end

  defp create_yearly_session(%{assigns: %{license: license}} = socket) do
    case StripeClient.create_subscription_session(license, :yearly) do
      {:ok, id} ->
        socket
        |> assign(loading: true)
        |> push_event("redirect-to-checkout", %{id: id, key: public_key()})

      _ ->
        socket |> put_flash(:error, dgettext("licenses", "Can't create subscription"))
    end
  end

  defp public_key do
    Application.get_env(:stripity_stripe, :public_key)
  end

  defp trigger_fetch_subscription(%{assigns: %{license: %{subscription_id: nil}}} = socket),
    do: socket

  defp trigger_fetch_subscription(socket) do
    send(self(), {:fetch_subscription})

    socket |> assign(loading: true)
  end

  defp fetch_subscription(%{assigns: %{license: license}} = socket) do
    case StripeClient.find_subscription(license) do
      nil ->
        socket
        |> put_flash(:error, dgettext("licenses", "Can't get your subscription"))

      subscription ->
        socket |> assign(subscription: subscription)
    end
  end

  defp redirect_to_customer(%{assigns: %{license: license}} = socket) do
    case StripeClient.create_billing_session(license) do
      {:ok, url} ->
        socket |> assign(loading: true) |> redirect(external: url)

      _ ->
        socket
        |> put_flash(:error, dgettext("licenses", "Can't get your subscription"))
    end
  end

  defp status(license) do
    statuses = invert(@statuses)

    statuses[license.status]
  end

  defp money(money), do: "#{money.currency} #{Money.to_string(money, symbol: true)}"

  defp subscription_info(%{loading: true}) do
    content_tag(:div, nil, class: "spinner-border text-primary")
  end

  defp subscription_info(%{license: %{subscription_id: nil} = license}) do
    [monthly_button(license), yearly_button(license)]
  end

  defp subscription_info(%{subscription: %{}}) do
    dgettext("licenses", "Show / modify subscription")
    |> link(to: "#", phx_click: "customer-info", class: "text-primary")
  end

  defp subscription_info(_assigns), do: nil

  defp monthly_button(license) do
    price = License.price_for(license)

    button =
      content_tag(:p, class: "mb-1") do
        dgettext("licenses", "Monthly pay %{money}", money: money(price))
        |> link(
          to: "#",
          phx_click: "monthly",
          class: "btn btn-outline-primary btn-lg rounded-pill px-3 border border-primary"
        )
      end

    text =
      content_tag(:p, class: "mb-3") do
        date =
          license.paid_until
          |> Timex.shift(months: 1)
          |> localize_date()

        content_tag(:span, dgettext("licenses", "Until %{date}", date: date), class: "text-muted")
      end

    [
      button,
      text
    ]
  end

  defp yearly_button(license) do
    price = License.price_for(license, :yearly)

    button =
      content_tag(:p, class: "mb-1") do
        dgettext("licenses", "Yearly pay %{money}", money: money(price))
        |> link(to: "#", phx_click: "yearly", class: "btn btn-primary btn-lg rounded-pill px-3")
      end

    text =
      content_tag(:p) do
        date =
          license.paid_until
          |> Timex.shift(years: 1)
          |> localize_date()

        content_tag(:span, dgettext("licenses", "Until %{date} Save two months!", date: date),
          class: "text-muted"
        )
      end

    [button, text]
  end

  defp subscription_plan(%{plan: plan}) do
    "#{translate_interval(plan.interval)} - #{money(Money.new(plan.amount, plan.currency))}"
  end

  defp translate_interval("month"), do: dgettext("licenses", "Monthly")
  defp translate_interval("year"), do: dgettext("licenses", "Yearly")
end
