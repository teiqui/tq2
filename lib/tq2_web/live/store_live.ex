defmodule Tq2Web.StoreLive do
  use Tq2Web, :live_view

  alias Tq2.{Inventories, Shops, Transactions}
  alias Tq2.Transactions.Cart
  alias Tq2Web.{ButtonComponent, ItemComponent}

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    store = Shops.get_store!(slug)
    options = %{page: 1, page_size: page_size()}

    socket =
      socket
      |> assign(store: store)
      |> assign(options)
      |> load_cart(session)
      |> load_items(store.account)

    {:ok, socket, temporary_assigns: [cart: nil, items: []]}
  end

  @impl true
  def handle_event("load-more", _, %{assigns: %{store: store}} = socket) do
    socket =
      socket
      |> update(:page, &(&1 + 1))
      |> load_items(store.account)

    {:noreply, socket}
  end

  defp load_cart(%{assigns: %{store: %{account: account}}} = socket, %{"token" => token}) do
    cart = Transactions.get_cart(account, token) || %Cart{lines: []}

    assign(socket, cart: cart)
  end

  defp load_items(socket, account) do
    items =
      Inventories.list_visible_items(account, %{
        page: socket.assigns.page,
        page_size: socket.assigns.page_size
      })

    assign(socket, items: items)
  end

  defp page_size do
    case Mix.env() do
      :test -> 1
      _ -> 30
    end
  end
end
