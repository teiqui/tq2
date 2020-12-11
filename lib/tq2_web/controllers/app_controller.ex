defmodule Tq2Web.AppController do
  use Tq2Web, :controller

  alias Tq2.Apps

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def index(conn, _params, session) do
    apps = Apps.list_apps(session.account)

    render(conn, "index.html", apps: apps, account: session.account)
  end

  def new(conn, %{"name" => "mercado_pago"}, session) do
    render(conn, "new_mercado_pago.html", account: session.account)
  end

  def edit(conn, %{"name" => "mercado_pago"}, session) do
    app = Apps.get_app(session.account, "mercado_pago")
    changeset = Apps.change_app(session.account, app)

    render(conn, "edit_mercado_pago.html",
      account: session.account,
      app: app,
      changeset: changeset,
      action: Routes.app_path(conn, :update, app)
    )
  end

  def update(conn, %{"mercado_pago" => app_params}, session) do
    app = Apps.get_app(session.account, "mercado_pago")

    case Apps.update_app(session, app, app_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, dgettext("apps", "App updated successfully."))
        |> redirect(to: Routes.app_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit_mercado_pago.html",
          account: session.account,
          app: app,
          changeset: changeset,
          action: Routes.app_path(conn, :update, app)
        )
    end
  end

  def delete(conn, %{"name" => app_name}, session) do
    app = Apps.get_app(session.account, app_name)
    {:ok, _app} = Apps.delete_app(session, app)

    conn
    |> put_flash(:info, dgettext("apps", "App deleted successfully."))
    |> redirect(to: Routes.app_path(conn, :index))
  end
end
