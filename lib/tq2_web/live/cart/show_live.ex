defmodule Tq2Web.Cart.ShowLive do
  use Tq2Web, :live_view

  import Tq2.Utils.Urls, only: [store_uri: 0]
  import Tq2Web.Utils, only: [localize_date: 1]
  import Tq2Web.Utils.Cart, only: [cart_total: 2, line_price: 2, line_total: 3]

  alias Tq2.Shops
  alias Tq2.Transactions

  @impl true
  def mount(_, %{"current_session" => %{account: account}}, socket) do
    socket = socket |> assign(account: account)

    {:ok, socket}
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
  def handle_params(%{"id" => id}, _url, %{assigns: %{account: account}} = socket) do
    cart = account |> Transactions.get_cart!(id)
    store = account |> Shops.get_store!()
    account = %{account | store: store}
    socket = socket |> assign(account: account, cart: cart)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "send-reminder",
        _params,
        %{assigns: %{account: account, cart: cart}} = socket
      ) do
    data =
      cart.data
      |> Transactions.Data.from_struct()
      |> Map.put(:notified_at, Timex.now())

    case Transactions.update_cart(account, cart, %{data: data}) do
      {:ok, updated_cart} ->
        cart = %{cart | data: updated_cart.data}
        socket = socket |> assign(:cart, cart)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp cart_handing(%{data: %{handing: "pickup"}}), do: dgettext("orders", "Pickup")

  defp cart_handing(%{data: %{shipping: %{name: name}}}) do
    [dgettext("orders", "Delivery"), name] |> Enum.join(" | ")
  end

  defp cart_handing(_cart), do: nil

  defp cart_price_type("regular"), do: dgettext("carts", "Regular")

  defp cart_price_type("promotional") do
    content_tag(:span, dgettext("carts", "Teiqui"), class: "text-primary")
  end

  defp resume_cart_url(store, %{id: id}) do
    store_uri() |> Routes.cart_url(:show, store, id)
  end

  defp can_be_notified?(%{data: %{notified_at: %DateTime{} = notified_at}}) do
    DateTime.utc_now()
    |> Timex.shift(hours: -1)
    |> DateTime.compare(notified_at)
    |> Kernel.==(:gt)
  end

  defp can_be_notified?(_), do: true
end
