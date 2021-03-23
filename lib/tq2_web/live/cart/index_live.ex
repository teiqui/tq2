defmodule Tq2Web.Cart.IndexLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils, only: [localize_date: 1]
  import Tq2Web.Utils.Cart, only: [cart_total: 2]
  import Scrivener.HTML, only: [pagination_links: 3]

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
  def handle_params(params, _url, %{assigns: %{account: account}} = socket) do
    page = params["page"]
    carts = account |> Transactions.get_carts(%{page: page})
    socket = socket |> assign(carts: carts, page: page)

    {:noreply, socket}
  end

  defp link_to_show(socket, cart) do
    icon_link(
      "eye-fill",
      title: dgettext("cart", "Show"),
      to: Routes.cart_path(socket, :show, cart),
      class: "ml-2"
    )
  end
end
