defmodule Tq2Web.Store.CheckoutLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils, only: [format_money: 1]
  import Tq2Web.Utils.Cart, only: [cart_total: 2, line_total: 3, teiqui_logo_img_tag: 1]

  alias Tq2.{Analytics, Transactions}
  alias Tq2.Transactions.{Cart, Line}
  alias Tq2Web.Store.{ButtonComponent, HeaderComponent, ProgressComponent}

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    visit = Analytics.get_visit!(visit_id)

    socket
    |> assign(
      store: store,
      token: token,
      visit_id: visit_id,
      referral_customer: visit.referral_customer,
      referred: !!visit.referral_customer
    )
    |> load_cart()
    |> finish_mount()
  end

  @impl true
  def handle_event(
        "increase",
        %{"id" => id},
        %{assigns: %{token: token, store: %{account: account}}} = socket
      ) do
    cart = Transactions.get_cart(account, token)
    line = Transactions.get_line!(cart, id)

    cart = cart |> update_quantity(line, line.quantity + 1)

    socket =
      socket
      |> assign(:cart, cart)
      |> load_shipping()

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "decrease",
        %{"id" => id},
        %{assigns: %{token: token, store: %{account: account}}} = socket
      ) do
    cart = Transactions.get_cart(account, token)
    line = Transactions.get_line!(cart, id)

    cart = cart |> decrease_quantity(line)

    socket =
      socket
      |> assign(:cart, cart)
      |> load_shipping()

    {:noreply, socket}
  end

  defp finish_mount(%{assigns: %{cart: nil, store: store}} = socket) do
    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:ok, socket}
  end

  defp finish_mount(socket) do
    socket = socket |> load_shipping()

    {:ok, socket,
     temporary_assigns: [cart: nil, items: [], referral_customer: nil, shipping: nil]}
  end

  defp update_quantity(cart, line, new_quantity) do
    case Transactions.update_line(cart, %{line | cart: cart}, %{quantity: new_quantity}) do
      {:ok, line} ->
        %{cart | lines: [line | Enum.filter(cart.lines, &(&1.id != line.id))]}

      {:error, _changeset} ->
        # TODO: handle this case properly
        cart
    end
  end

  defp decrease_quantity(cart, %Line{quantity: 1} = line) do
    case Transactions.delete_line(line) do
      {:ok, _line} ->
        %{cart | lines: Enum.filter(cart.lines, &(&1.id != line.id))}

      {:error, _changeset} ->
        # TODO: handle this case properly
        cart
    end
  end

  defp decrease_quantity(cart, line) do
    cart |> update_quantity(line, line.quantity - 1)
  end

  defp load_cart(%{assigns: %{store: %{account: account}, token: token}} = socket) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp regular_cart_total(%Cart{} = cart) do
    %{cart | price_type: "regular"}
    |> Cart.total()
    |> format_money()
  end

  defp load_shipping(%{assigns: %{cart: cart}} = socket) do
    socket |> assign(:shipping, Cart.shipping(cart))
  end
end
