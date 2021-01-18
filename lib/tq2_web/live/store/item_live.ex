defmodule Tq2Web.Store.ItemLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts.Account
  alias Tq2.{Analytics, Inventories, Transactions}
  alias Tq2.Inventories.Item
  alias Tq2.Transactions.Cart
  alias Tq2Web.Store.HeaderComponent

  import Tq2Web.ItemView, only: [money: 1]

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    visit = Analytics.get_visit!(visit_id)

    socket =
      socket
      |> assign(
        store: store,
        token: token,
        visit_id: visit_id,
        quantity: 1,
        referral_customer: visit.referral_customer,
        referred: !!visit.referral_customer
      )
      |> load_cart(token)

    {:ok, socket, temporary_assigns: [item: nil, referral_customer: nil]}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, %{assigns: %{store: store}} = socket) do
    item = Inventories.get_item!(store.account, id)

    {:noreply, assign(socket, item: item, item_id: item.id)}
  end

  @impl true
  def handle_event("increase", _params, %{assigns: %{quantity: quantity}} = socket) do
    {:noreply, assign(socket, :quantity, quantity + 1)}
  end

  @impl true
  def handle_event("decrease", _params, %{assigns: %{quantity: quantity}} = socket)
      when quantity > 1 do
    {:noreply, assign(socket, :quantity, quantity - 1)}
  end

  @impl true
  def handle_event("decrease", _params, %{assigns: %{quantity: quantity}} = socket) do
    {:noreply, assign(socket, :quantity, quantity)}
  end

  @impl true
  def handle_event(
        "add",
        %{"type" => price_type, "id" => id},
        %{
          assigns: %{
            cart: cart,
            store: store,
            token: token,
            quantity: quantity,
            visit_id: visit_id
          }
        } = socket
      ) do
    item = Inventories.get_item!(store.account, id)

    cart =
      store.account
      |> cart(cart, %{token: token, price_type: price_type, visit_id: visit_id})
      |> add_line(item, quantity)

    socket =
      socket
      |> assign(cart: cart)
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:noreply, socket}
  end

  defp load_cart(%{assigns: %{referred: referred, store: %{account: account}}} = socket, token) do
    cart = Transactions.get_cart(account, token) || %Cart{referred: referred, lines: []}

    assign(socket, cart: cart)
  end

  defp cart(%Account{} = account, %Cart{id: nil}, attrs) do
    {:ok, cart} = Transactions.create_cart(account, attrs)

    %{cart | lines: []}
  end

  defp cart(%Account{}, %Cart{price_type: price_type} = cart, %{price_type: price_type}) do
    cart
  end

  defp cart(%Account{} = account, %Cart{} = cart, %{price_type: price_type}) do
    {:ok, cart} = Transactions.update_cart(account, cart, %{price_type: price_type})

    cart
  end

  defp add_line(%Cart{} = cart, %Item{} = item, quantity) do
    case Enum.find(cart.lines, &(&1.item_id == item.id)) do
      nil ->
        {:ok, line} = Transactions.create_line(cart, %{item: item, quantity: quantity})

        %{cart | lines: [line | cart.lines]}

      line ->
        {:ok, line} =
          Transactions.update_line(cart, %{line | item: item, cart: cart}, %{
            quantity: line.quantity + quantity
          })

        %{cart | lines: [line | Enum.filter(cart.lines, &(&1.id != line.id))]}
    end
  end

  defp image(%Item{image: nil} = item) do
    ~E"""
      <svg class="img-fluid mb-3"
           viewBox="0 0 280 280"
           width="280"
           height="280"
           xmlns="http://www.w3.org/2000/svg"
           focusable="false"
           role="img"
           aria-label="<%= item.name %>">
        <g>
          <title><%= item.name %></title>
          <rect width="280" height="280" x="0" y="0" fill="#c4c4c4"></rect>
          <text x="50%" y="50%" text-anchor="middle" alignment-baseline="middle" fill="#838383" dy=".3em">
            <%= String.slice(item.name, 0..10) %>
          </text>
        </g>
      </svg>
    """
  end

  defp image(%Item{image: image} = item) do
    url = Tq2.ImageUploader.url({image, item}, :preview)

    set = %{
      url => "1x",
      Tq2.ImageUploader.url({image, item}, :preview_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "280",
      height: "280",
      loading: "lazy",
      alt: item.name,
      class: "img-fluid mb-3"
    )
  end

  defp regular_price_button(%Cart{referred: false, lines: []} = cart, item) do
    regular_price_button(cart, item, false)
  end

  defp regular_price_button(%Cart{price_type: "regular"} = cart, item) do
    regular_price_button(cart, item, false)
  end

  defp regular_price_button(cart, item) do
    regular_price_button(cart, item, true)
  end

  defp regular_price_button(_cart, %Item{id: id, price: price}, disabled) do
    content_tag(:button, money(price),
      type: "button",
      class:
        "btn btn-outline-primary btn-lg btn-block rounded-pill px-3 border border-primary mr-3",
      disabled: disabled,
      phx_click: "add",
      phx_value_id: id,
      phx_value_type: "regular"
    )
  end

  defp promotional_price_button(socket, %Cart{referred: false, lines: []} = cart, item) do
    promotional_price_button(socket, cart, item, false)
  end

  defp promotional_price_button(socket, %Cart{price_type: "promotional"} = cart, item) do
    promotional_price_button(socket, cart, item, false)
  end

  defp promotional_price_button(socket, cart, item) do
    promotional_price_button(socket, cart, item, true)
  end

  defp promotional_price_button(socket, _cart, %Item{id: id, promotional_price: price}, disabled) do
    content = ~E"""
    <img src="<%= Routes.static_path(socket, "/images/favicon_white.svg") %>"
         class="mt-n1"
         height="16"
         width="16"
         alt="Teiqui">
    <%= money price %>
    """

    content_tag(:button, content,
      type: "button",
      class: "btn btn-primary btn-lg btn-block rounded-pill px-4",
      disabled: disabled,
      phx_click: "add",
      phx_value_id: id,
      phx_value_type: "promotional"
    )
  end
end
