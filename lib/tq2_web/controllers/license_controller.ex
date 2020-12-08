defmodule Tq2Web.LicenseController do
  use Tq2Web, :controller

  alias Tq2.Accounts
  alias Tq2.Payments

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, session])
  end

  def show(conn, session) do
    license = Accounts.get_license!(session.account)
    payments = Payments.list_recent_license_payments(session.account)

    render(conn, "show.html", license: license, payments: payments)
  end
end
