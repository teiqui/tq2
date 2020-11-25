defmodule Tq2Web.License.CheckController do
  use Tq2Web, :controller

  alias Tq2.Gateways.MercadoPago

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, session])
  end

  def show(conn, session) do
    message =
      case MercadoPago.update_license_with_last_payment(session.account) do
        true -> dgettext("licenses", "License updated")
        false -> dgettext("licenses", "Nothing to update")
      end

    path = Routes.license_path(conn, :show)

    conn
    |> put_flash(:info, message)
    |> redirect(to: path)
  end
end
