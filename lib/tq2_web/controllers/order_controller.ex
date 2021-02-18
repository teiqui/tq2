defmodule Tq2Web.OrderController do
  use Tq2Web, :controller

  alias Tq2.Sales
  alias Tq2.Transactions.Cart

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def index(conn, params, session) do
    page = Sales.list_orders(session.account, params)

    render_index(conn, page)
  end

  def show(conn, %{"id" => id}, session) do
    order = Sales.get_order!(session.account, id)
    payments = order.cart.payments |> Enum.reject(&(&1.status == "cancelled"))
    shipping = Cart.shipping(order.cart)

    render(conn, "show.html", order: order, payments: payments, shipping: shipping)
  end

  defp render_index(conn, %{total_entries: 0}), do: render(conn, "empty.html")

  defp render_index(conn, page) do
    render(conn, "index.html", orders: page.entries, page: page)
  end
end
