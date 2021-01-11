defmodule Tq2Web.Account.LicenseLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils, only: [invert: 1, localize_date: 1]

  alias Tq2.Accounts

  @statuses %{
    dgettext("licenses", "Trial") => "trial",
    dgettext("licenses", "Active") => "active",
    dgettext("licenses", "Unpaid") => "unpaid",
    dgettext("licenses", "Locked") => "locked",
    dgettext("licenses", "Canceled") => "canceled"
  }

  @impl true
  def mount(_, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)
    license = Accounts.get_license!(session.account)

    socket = socket |> assign(license: license)

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> put_flash(:error, dgettext("sessions", "You must be logged in."))
      |> redirect(to: Routes.root_path(socket, :index))

    {:ok, socket}
  end

  defp status(license) do
    statuses = invert(@statuses)

    statuses[license.status]
  end

  def money(money), do: "#{money.currency} #{Money.to_string(money, symbol: true)}"
end
