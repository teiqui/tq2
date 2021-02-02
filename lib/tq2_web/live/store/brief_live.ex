defmodule Tq2Web.Store.BriefLive do
  use Tq2Web, :live_view

  import Tq2Web.PaymentLiveUtils, only: [create_order: 3, create_mp_payment: 3]
  import Tq2Web.Utils, only: [format_money: 1]

  alias Tq2.{Sales, Transactions}
  alias Tq2.Transactions.Cart
  alias Tq2Web.Store.{ButtonComponent, HeaderComponent}

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    socket
    |> assign(store: store, token: token, visit_id: visit_id)
    |> load_cart()
    |> finish_mount()
  end

  @impl true
  def handle_event(
        "save",
        _params,
        %{assigns: %{store: %{account: account} = store, token: token}} = socket
      ) do
    cart = Transactions.get_cart(account, token)

    case cart.data.payment do
      "mercado_pago" ->
        socket = socket |> create_mp_payment(store, cart)

        {:noreply, socket}

      _ ->
        socket = socket |> create_order(store, cart)

        {:noreply, socket}
    end
  end

  defp finish_mount(%{assigns: %{cart: nil, store: store}} = socket) do
    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:ok, socket}
  end

  defp finish_mount(socket) do
    socket = socket |> load_previous_order()

    {:ok, socket, temporary_assigns: [cart: nil]}
  end

  defp load_cart(%{assigns: %{store: %{account: account}, token: token}} = socket) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp load_previous_order(%{assigns: %{store: store, token: token}} = socket) do
    case Sales.get_latest_order(store.account, token) do
      nil ->
        socket |> push_redirect(to: Routes.handing_path(socket, :index, store))

      order ->
        maybe_copy_previous_cart_data(socket, order.cart)
    end
  end

  defp maybe_copy_previous_cart_data(%{assigns: %{cart: cart, store: store}} = socket, other) do
    case Transactions.can_be_copied?(store, cart, other) do
      true ->
        case Transactions.fill_cart(store, cart, other) do
          %Cart{data: %{copied: true}} = cart ->
            assign(socket, cart: cart)

          _ ->
            push_redirect(socket, to: Routes.handing_path(socket, :index, store))
        end

      _ ->
        socket
    end
  end

  defp cart_total(%Cart{} = cart) do
    cart
    |> Cart.total()
    |> format_money()
  end

  defp line_total(cart, line) do
    cart
    |> Cart.line_total(line)
    |> format_money()
  end

  defp cart_total_hint(%Cart{price_type: "promotional"} = cart) do
    total = cart |> Cart.total()
    regular = %{cart | price_type: "regular"} |> Cart.total()
    savings = Money.subtract(regular, total) |> format_money()

    dgettext("stores", "You saved %{amount}", amount: savings)
  end

  defp cart_total_hint(%Cart{} = cart) do
    total = cart |> Cart.total()
    promotional = %{cart | price_type: "promotional"} |> Cart.total()
    savings = Money.subtract(total, promotional) |> format_money()

    dgettext("stores", "You could have saved %{amount}", amount: savings)
  end

  defp payment("cash") do
    dgettext("payments", "Cash")
  end

  defp payment("mercado_pago") do
    dgettext("payments", "MercadoPago")
  end

  defp payment("wire_transfer") do
    dgettext("payments", "Wire transfer")
  end
end
