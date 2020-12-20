defmodule Tq2Web.Store.OrderLive do
  use Tq2Web, :live_view

  alias Tq2.{Sales, Shops}
  alias Tq2Web.Store.HeaderComponent

  @impl true
  def mount(%{"slug" => slug, "id" => id}, %{"token" => token}, socket) do
    store = Shops.get_store!(slug)

    socket =
      socket
      |> assign(store: store, token: token)
      |> load_order(id)

    {:ok, socket, temporary_assigns: [order: nil]}
  end

  defp load_order(%{assigns: %{store: %{account: account}}} = socket, id) do
    order = Sales.get_order!(account, id)

    assign(socket, order: order)
  end
end
