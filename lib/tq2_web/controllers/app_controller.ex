defmodule Tq2Web.AppController do
  use Tq2Web, :controller

  alias Tq2.Apps
  alias Tq2.Apps.{Conekta, MercadoPago, Transbank, WireTransfer}

  @app_names ~w(conekta mercado_pago transbank wire_transfer)
  @app_structs %{
    "conekta" => %Conekta{},
    "mercado_pago" => %MercadoPago{},
    "transbank" => %Transbank{},
    "wire_transfer" => %WireTransfer{}
  }

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def index(conn, _params, session) do
    apps = Apps.list_apps(session.account)

    render(conn, "index.html", apps: apps, account: session.account)
  end

  def new(conn, %{"name" => app_name}, session) when app_name in @app_names do
    changeset = Apps.change_app(session.account, @app_structs[app_name])

    render(conn, "new.html",
      account: session.account,
      changeset: changeset,
      app_name: app_name,
      action: Routes.app_path(conn, :create, %{name: app_name})
    )
  end

  def create(conn, %{"conekta" => app_params}, session) do
    conn |> create_app("conekta", app_params, session)
  end

  def create(conn, %{"mercado_pago" => app_params}, session) do
    conn |> create_app("mercado_pago", app_params, session)
  end

  def create(conn, %{"transbank" => app_params}, session) do
    conn |> create_app("transbank", app_params, session)
  end

  def create(conn, %{"wire_transfer" => app_params}, session) do
    conn |> create_app("wire_transfer", app_params, session)
  end

  def edit(conn, %{"name" => app_name}, session) when app_name in @app_names do
    app = Apps.get_app(session.account, app_name)
    changeset = Apps.change_app(session.account, app)

    render(conn, "edit.html",
      account: session.account,
      app: app,
      app_name: app_name,
      changeset: changeset,
      action: Routes.app_path(conn, :update, app)
    )
  end

  def update(conn, %{"conekta" => app_params}, session) do
    conn |> update_app("conekta", app_params, session)
  end

  def update(conn, %{"mercado_pago" => app_params}, session) do
    conn |> update_app("mercado_pago", app_params, session)
  end

  def update(conn, %{"transbank" => app_params}, session) do
    conn |> update_app("transbank", app_params, session)
  end

  def update(conn, %{"wire_transfer" => app_params}, session) do
    conn |> update_app("wire_transfer", app_params, session)
  end

  def delete(conn, %{"name" => app_name}, session) when app_name in @app_names do
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
        render(conn, "edit.html",
          account: session.account,
          app: app,
          app_name: app_name,
          changeset: changeset,
          action: Routes.app_path(conn, :update, app)
        )
    end
  end

  defp create_app(conn, app_name, app_params, session) do
    app_params = app_params |> Map.put("name", app_name)

    case Apps.create_app(session, app_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, dgettext("apps", "App created successfully."))
        |> redirect(to: Routes.app_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html",
          account: session.account,
          changeset: changeset,
          app_name: app_name,
          action: Routes.app_path(conn, :create, %{name: app_name})
        )
    end
  end
end
