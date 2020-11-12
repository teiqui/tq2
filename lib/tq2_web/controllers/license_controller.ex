defmodule Tq2Web.LicenseController do
  use Tq2Web, :controller

  alias Tq2.Accounts

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def show(conn, _params \\ %{}, session) do
    license = Accounts.get_license!(session.account)

    render(conn, "show.html", license: license)
  end
end
