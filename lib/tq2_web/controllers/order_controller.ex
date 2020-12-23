defmodule Tq2Web.OrderController do
  use Tq2Web, :controller

  alias Tq2.Sales

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

    render(conn, "show.html", order: order)
  end

  def edit(conn, %{"id" => id}, session) do
    order = Sales.get_order!(session.account, id)
    changeset = Sales.change_order(session.account, order)

    render(conn, "edit.html",
      order: order,
      changeset: changeset,
      action: Routes.order_path(conn, :update, order)
    )
  end

  def update(conn, %{"id" => id, "order" => order_params}, session) do
    order = Sales.get_order!(session.account, id)

    case Sales.update_order(session, order, order_params) do
      {:ok, order} ->
        conn
        |> put_flash(:info, dgettext("orders", "Order updated successfully."))
        |> redirect(to: Routes.order_path(conn, :show, order))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html",
          order: order,
          changeset: changeset,
          action: Routes.order_path(conn, :update, order)
        )
    end
  end

  defp render_index(conn, %{total_entries: 0}), do: render(conn, "empty.html")

  defp render_index(conn, page) do
    render(conn, "index.html", orders: page.entries, page: page)
  end
end
