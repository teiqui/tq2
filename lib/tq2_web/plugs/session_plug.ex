defmodule Tq2Web.SessionPlug do
  import Phoenix.Controller
  import Plug.Conn
  import Tq2Web.Gettext

  alias Tq2.Accounts
  alias Tq2Web.Router.Helpers, as: Routes

  def fetch_current_session(%{assigns: %{current_session: session}} = conn, _opts)
      when is_map(session),
      do: conn

  def fetch_current_session(conn, _opts) do
    account_id = get_session(conn, :account_id)
    user_id = get_session(conn, :user_id)
    session = Accounts.get_current_session(account_id, user_id)

    assign(conn, :current_session, session)
  end

  def authenticate(%{assigns: %{current_session: session}} = conn, _opts)
      when is_map(session),
      do: conn

  def authenticate(conn, _opts) do
    conn
    |> put_return_path()
    |> put_flash(:error, dgettext("sessions", "You must be logged in."))
    |> redirect(to: Routes.session_path(conn, :new))
    |> halt()
  end

  def session_extras(%{assigns: %{store: store}, remote_ip: ip} = conn, :store) do
    hide_price_info = conn |> get_session(:hide_price_info)

    %{"remote_ip" => ip, "store" => store, "hide_price_info" => hide_price_info}
  end

  def session_extras(%{params: params, remote_ip: ip}, :registration) do
    %{"campaign" => params["utm_campaign"], "remote_ip" => ip}
  end

  def session_extras(
        %{assigns: %{current_session: current_session}},
        :current_session
      ) do
    %{
      "current_session" => current_session
    }
  end

  defp put_return_path(%{method: "GET", request_path: request_path} = conn)
       when request_path != "/" do
    put_session(conn, :previous_url, current_path(conn))
  end

  defp put_return_path(conn), do: conn
end
