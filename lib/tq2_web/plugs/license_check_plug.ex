defmodule Tq2Web.LicenseCheckPlug do
  import Phoenix.Controller
  import Plug.Conn
  import Tq2Web.Gettext

  alias Tq2Web.Router.Helpers, as: Routes

  @always_enabled_paths ~w[/license /sessions]

  def check_locked_license(%{request_path: path} = conn, _opts)
      when path in @always_enabled_paths,
      do: conn

  def check_locked_license(
        %{assigns: %{current_session: %{account: %{status: "locked"}}}} = conn,
        _opts
      ) do
    conn
    |> put_flash(:error, dgettext("licenses", "Your license has expired."))
    |> redirect(to: Routes.license_path(conn, :index))
    |> halt()
  end

  def check_locked_license(conn, _opts), do: conn
end
