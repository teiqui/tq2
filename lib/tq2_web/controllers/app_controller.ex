defmodule Tq2Web.AppController do
  use Tq2Web, :controller

  alias Tq2.Apps
  alias Tq2.Apps.WireTransfer

  @app_names ~w(mercado_pago wire_transfer)

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

  def new(conn, %{"name" => "wire_transfer"}, session) do
    changeset = Apps.change_app(session.account, %WireTransfer{})

    render(conn, "new_wire_transfer.html",
      changeset: changeset,
      action: Routes.app_path(conn, :create, %{name: "wire_transfer"})
    )
  end

  def create(conn, %{"wire_transfer" => app_params}, session) do
    app_params = app_params |> Map.put("name", "wire_transfer")

    case Apps.create_app(session, app_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, dgettext("apps", "App updated successfully."))
        |> redirect(to: Routes.app_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new_wire_transfer.html",
          changeset: changeset,
          action: Routes.app_path(conn, :create, %{name: "wire_transfer"})
        )
    end
  end

  def edit(conn, %{"name" => app_name}, session) when app_name in @app_names do
    app = Apps.get_app(session.account, app_name)
    changeset = Apps.change_app(session.account, app)

    render(conn, "edit_#{app_name}.html",
      account: session.account,
      app: app,
      changeset: changeset,
      action: Routes.app_path(conn, :update, app)
    )
  end

  def update(conn, %{"mercado_pago" => app_params}, session) do
    conn |> update_app("mercado_pago", app_params, session)
  end

  def update(conn, %{"wire_transfer" => app_params}, session) do
    conn |> update_app("wire_transfer", app_params, session)
  end

  def delete(conn, %{"name" => app_name}, session) do
    app = Apps.get_app(session.account, app_name)
    {:ok, _app} = Apps.delete_app(session, app)

    conn
    |> put_flash(:info, dgettext("apps", "App deleted successfully."))
    |> redirect(to: Routes.app_path(conn, :index))
  end

  defp update_app(conn, app_name, app_params, session) do
    app = Apps.get_app(session.account, app_name)

    case Apps.update_app(session, app, app_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, dgettext("apps", "App updated successfully."))
        |> redirect(to: Routes.app_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit_#{app_name}.html",
          account: session.account,
          app: app,
          changeset: changeset,
          action: Routes.app_path(conn, :update, app)
        )
    end
  end
end
