defmodule Tq2Web.StoreController do
  use Tq2Web, :controller

  alias Tq2.Shops
  alias Tq2.Shops.Store

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def show(conn, _params, session) do
    case Shops.get_store(session.account) do
      %Store{} ->
        redirect(conn, to: Routes.store_path(conn, :edit))

      nil ->
        redirect(conn, to: Routes.store_path(conn, :new))
    end
  end

  def new(conn, _params, session) do
    changeset = Shops.change_store(session.account, %Store{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"store" => store_params}, session) do
    case Shops.create_store(session, store_params) do
      {:ok, _store} ->
        conn
        |> put_flash(:info, dgettext("stores", "Store created successfully."))
        |> redirect(to: Routes.store_path(conn, :edit))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, _params, session) do
    store = Shops.get_store!(session.account)
    changeset = Shops.change_store(session.account, store)

    render(conn, "edit.html", store: store, changeset: changeset)
  end

  def update(conn, %{"store" => store_params}, session) do
    store = Shops.get_store!(session.account)

    case Shops.update_store(session, store, store_params) do
      {:ok, _store} ->
        conn
        |> put_flash(:info, dgettext("stores", "Store updated successfully."))
        |> redirect(to: Routes.store_path(conn, :edit))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", store: store, changeset: changeset)
    end
  end
end
