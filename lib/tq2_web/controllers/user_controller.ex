defmodule Tq2Web.UserController do
  use Tq2Web, :controller

  alias Tq2.Accounts
  alias Tq2.Accounts.User

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def index(conn, params, session) do
    page = Accounts.list_users(session.account, params)

    render_index(conn, page)
  end

  def new(conn, _params, _session) do
    changeset = Accounts.change_user(%User{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}, session) do
    case Accounts.create_user(session, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("users", "User created successfully."))
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, session) do
    user = Accounts.get_user!(session.account, id)

    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}, session) do
    user = Accounts.get_user!(session.account, id)
    changeset = Accounts.change_user(user)

    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}, session) do
    user = Accounts.get_user!(session.account, id)

    case Accounts.update_user(session, user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("users", "User updated successfully."))
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, session) do
    user = Accounts.get_user!(session.account, id)
    {:ok, _user} = Accounts.delete_user(session, user)

    conn
    |> put_flash(:info, dgettext("users", "User deleted successfully."))
    |> redirect(to: Routes.user_path(conn, :index))
  end

  defp render_index(conn, %{total_entries: 0}), do: render(conn, "empty.html")

  defp render_index(conn, page) do
    render(conn, "index.html", users: page.entries, page: page)
  end
end
