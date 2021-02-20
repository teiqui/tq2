defmodule Tq2Web.ItemController do
  use Tq2Web, :controller

  alias Tq2.Inventories
  alias Tq2.Inventories.Item

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

  def new(conn, _params, session) do
    changeset = Inventories.change_item(session.account, %Item{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"item" => item_params} = params, session) do
    case Inventories.create_item(session, item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, dgettext("items", "Item created successfully."))
        |> redirect(to: after_create_path(conn, params, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, session) do
    item = Inventories.get_item!(session.account, id)

    render(conn, "show.html", item: item)
  end

  def edit(conn, %{"id" => id}, session) do
    item = Inventories.get_item!(session.account, id)
    changeset = Inventories.change_item(session.account, item)

    render(conn, "edit.html", item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => item_params}, session) do
    item = Inventories.get_item!(session.account, id)

    case Inventories.update_item(session, item, item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, dgettext("items", "Item updated successfully."))
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", item: item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, session) do
    item = Inventories.get_item!(session.account, id)
    {:ok, _item} = Inventories.delete_item(session, item)

    conn
    |> put_flash(:info, dgettext("items", "Item deleted successfully."))
    |> redirect(to: Routes.item_path(conn, :index))
  end

  defp render_index(conn, %{total_entries: 0}, [{:search, nil} | _]),
    do: render(conn, "empty.html")

  defp render_index(conn, %{total_entries: 0}, assigns) do
    render(conn, "empty_search.html", assigns)
  end

  defp render_index(conn, page, assigns) do
    assigns = assigns ++ [items: page.entries, page: page]
    render(conn, "index.html", assigns)
  end

  defp after_create_path(conn, %{"tour" => _}, _item) do
    Routes.item_path(conn, :index, tour: "item_created")
  end

  defp after_create_path(conn, _params, item) do
    Routes.item_path(conn, :show, item)
  end

  defp permitted_params(params) do
    params
    |> Map.take(["page", "search"])
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end
end
