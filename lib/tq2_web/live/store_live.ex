defmodule Tq2Web.StoreLive do
  use Tq2Web, :live_view

  alias Tq2.Inventories
  alias Tq2.Shops
  alias Tq2Web.ItemComponent

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    store = Shops.get_store!(slug)
    options = %{page: 1, page_size: 30}

    socket =
      socket
      |> assign(store: store)
      |> assign(options)
      |> load_items(store.account)

    {:ok, socket, temporary_assigns: [items: []]}
  end

  @impl true
  def handle_event("load-more", _, %{assigns: %{store: store}} = socket) do
    socket =
      socket
      |> update(:page, &(&1 + 1))
      |> load_items(store.account)

    {:noreply, socket}
  end

  defp load_items(socket, account) do
    items =
      Inventories.list_visible_items(account, %{
        page: socket.assigns.page,
        page_size: socket.assigns.page_size
      })

    assign(socket, items: items)
  end
end
