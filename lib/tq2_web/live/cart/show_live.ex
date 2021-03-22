defmodule Tq2Web.Cart.ShowLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils, only: [localize_date: 1]
  import Tq2Web.Utils.Cart, only: [cart_total: 2, line_price: 2, line_total: 3]

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
    socket = socket |> assign(:cart, cart)

    {:noreply, socket}
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
end
