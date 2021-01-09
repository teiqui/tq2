defmodule Tq2Web.LicenseController do
  use Tq2Web, :controller

  alias Tq2.Accounts

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, session])
  end

  def show(conn, session) do
    license = Accounts.get_license!(session.account)

    render(conn, "show.html", license: license)
  end
end
