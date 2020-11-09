defmodule Tq2Web.CategoryController do
  use Tq2Web, :controller

  alias Tq2.Inventories
  alias Tq2.Inventories.Category

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def index(conn, params, session) do
    page = Inventories.list_categories(session.account, params)

    render_index(conn, page)
  end

  def new(conn, _params, session) do
    changeset = Inventories.change_category(session.account, %Category{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"category" => category_params}, session) do
    case Inventories.create_category(session, category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, dgettext("categories", "Category created successfully."))
        |> redirect(to: Routes.category_path(conn, :show, category))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, session) do
    category = Inventories.get_category!(session.account, id)

    render(conn, "show.html", category: category)
  end

  def edit(conn, %{"id" => id}, session) do
    category = Inventories.get_category!(session.account, id)
    changeset = Inventories.change_category(session.account, category)

    render(conn, "edit.html", category: category, changeset: changeset)
  end

  def update(conn, %{"id" => id, "category" => category_params}, session) do
    category = Inventories.get_category!(session.account, id)

    case Inventories.update_category(session, category, category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, dgettext("categories", "Category updated successfully."))
        |> redirect(to: Routes.category_path(conn, :show, category))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", category: category, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, session) do
    category = Inventories.get_category!(session.account, id)
    {:ok, _category} = Inventories.delete_category(session, category)

    conn
    |> put_flash(:info, dgettext("categories", "Category deleted successfully."))
    |> redirect(to: Routes.category_path(conn, :index))
  end

  defp render_index(conn, %{total_entries: 0}), do: render(conn, "empty.html")

  defp render_index(conn, page) do
    render(conn, "index.html", categories: page.entries, page: page)
  end
end
