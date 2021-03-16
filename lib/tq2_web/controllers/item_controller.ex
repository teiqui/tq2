defmodule Tq2Web.ItemController do
  use Tq2Web, :controller

  alias Tq2.Inventories

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def index(conn, params, session) do
    params = params |> permitted_params()
    page = Inventories.list_items(session.account, params)
    title = dgettext("items", "Items")

    render_index(conn, page, search: params[:search], searchable_title: title)
  end

  def show(conn, %{"id" => id}, session) do
    item = Inventories.get_item!(session.account, id)

    render(conn, "show.html", item: item)
  end

  def delete(conn, %{"id" => id}, session) do
    item = Inventories.get_item!(session.account, id)
    {:ok, _item} = Inventories.delete_item(session, item)

    conn
    |> put_flash(:info, dgettext("items", "Item deleted successfully."))
    |> redirect(to: Routes.item_path(conn, :index))
  end

  defp render_index(conn, %{total_entries: 0}, [{:search, nil} | _]) do
    render(conn, "empty.html")
  end

  defp render_index(conn, %{total_entries: 0}, assigns) do
    render(conn, "empty_search.html", assigns)
  end

  defp render_index(conn, page, assigns) do
    assigns = assigns ++ [items: page.entries, page: page]
    render(conn, "index.html", assigns)
  end

  defp permitted_params(params) do
    params
    |> Map.take(["page", "search"])
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end
end
