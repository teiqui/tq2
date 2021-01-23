defmodule Tq2Web.Registration.TourLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts

  @impl true
  def mount(_params, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)

    {:ok, assign(socket, account: session.account)}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> put_flash(:error, dgettext("sessions", "You must be logged in."))
      |> redirect(to: Routes.root_path(socket, :index))

    {:ok, socket}
  end
end
