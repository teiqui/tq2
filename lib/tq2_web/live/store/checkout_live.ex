defmodule Tq2Web.Store.CheckoutLive do
  use Tq2Web, :live_view

  alias Tq2.{Analytics, Transactions}
  alias Tq2.Transactions.{Cart, Line}
  alias Tq2Web.Store.{ButtonComponent, HeaderComponent}

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    visit = Analytics.get_visit!(visit_id)

    socket =
      socket
      |> assign(
        store: store,
        token: token,
        visit_id: visit_id,
        referral_customer: visit.referral_customer,
        referred: !!visit.referral_customer
      )
      |> load_cart(token)

    {:ok, socket, temporary_assigns: [cart: nil, items: [], referral_customer: nil]}
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

    {:noreply, assign(socket, cart: cart)}
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

    {:noreply, assign(socket, cart: cart)}
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

  defp load_cart(%{assigns: %{store: %{account: account}}} = socket, token) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp format_money(%Money{} = money) do
    Money.to_string(money, symbol: true)
  end

  defp line_total(socket, cart, line) do
    regular_total =
      %{cart | price_type: "regular"}
      |> Cart.line_total(line)
      |> format_money()

    promotional_total =
      %{cart | price_type: "promotional"}
      |> Cart.line_total(line)
      |> format_money()

    wrap_line_total(socket, cart, regular_total, promotional_total)
  end

  defp wrap_line_total(socket, %Cart{price_type: "promotional"}, regular_total, promotional_total) do
    ~E"""
      <del class="d-block">
        <%= regular_total %>
      </del>
      <div class="text-primary text-nowrap font-weight-bold">
        <%= teiqui_logo_img_tag(socket) %>
        <%= promotional_total %>
      </div>
    """
  end

  defp wrap_line_total(socket, _cart, regular_total, promotional_total) do
    ~E"""
      <div>
        <%= regular_total %>
      </div>
      <del class="d-block text-primary text-nowrap font-weight-bold">
        <%= teiqui_logo_img_tag(socket) %>
        <%= promotional_total %>
      </del>
    """
  end

  defp regular_cart_total(%Cart{} = cart) do
    %{cart | price_type: "regular"}
    |> Cart.total()
    |> format_money()
  end

  defp cart_total(socket, %Cart{} = cart) do
    total =
      cart
      |> Cart.total()
      |> format_money()

    wrap_cart_total(socket, cart, total)
  end

  defp wrap_cart_total(socket, %Cart{price_type: "promotional"}, total) do
    ~E"""
      <div class="text-primary text-nowrap font-weight-bold">
        <%= teiqui_logo_img_tag(socket) %>
        <%= total %>
      </div>
    """
  end

  defp wrap_cart_total(_socket, _cart, total) do
    content_tag(:div, total)
  end

  defp teiqui_logo_img_tag(socket) do
    socket
    |> Routes.static_path("/images/favicon.svg")
    |> img_tag(height: 11, width: 11, alt: "Teiqui", class: "mt-n1")
  end
end
