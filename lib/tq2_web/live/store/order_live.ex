defmodule Tq2Web.Store.OrderLive do
  use Tq2Web, :live_view

  alias Tq2.{Analytics, Sales, Shops}
  alias Tq2Web.Store.{HeaderComponent, ShareComponent}

  @impl true
  def mount(%{"slug" => slug, "id" => id}, %{"token" => token, "visit_id" => visit_id}, socket) do
    store = Shops.get_store!(slug)
    visit = Analytics.get_visit!(visit_id)

    socket =
      socket
      |> assign(
        store: store,
        token: token,
        visit_id: visit_id,
        referral_customer: visit.referral_customer
      )
      |> load_order(id)

    {:ok, socket, temporary_assigns: [order: nil, cart: nil, referral_customer: nil]}
  end

  defp load_order(%{assigns: %{store: %{account: account}}} = socket, id) do
    order = Sales.get_order!(account, id)

    assign(socket, order: order, cart: order.cart)
  end

  defp share_classes do
    "btn btn-primary rounded-pill py-2 px-4"
  end
end
