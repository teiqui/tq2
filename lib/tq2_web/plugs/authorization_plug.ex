defmodule Tq2Web.AuthorizationPlug do
  import Phoenix.Controller
  import Plug.Conn
  import Tq2Web.Gettext

  alias Tq2Web.Router.Helpers, as: Routes

  def authorize(%{assigns: %{current_session: %{user: user}}} = conn, opts) do
    user
    |> has_role?(opts[:as])
    |> maybe_halt(conn)
  end

  def authorize(conn, _opts), do: maybe_halt(false, conn)

  defp has_role?(nil, _roles), do: false
  defp has_role?(user, roles) when is_list(roles), do: Enum.any?(roles, &has_role?(user, &1))
  defp has_role?(user, role) when is_atom(role), do: has_role?(user, Atom.to_string(role))
  defp has_role?(%{role: role}, role), do: true
  defp has_role?(_user, _role), do: false

  defp maybe_halt(true, conn), do: conn

  defp maybe_halt(_, conn) do
    conn
    |> put_flash(:error, dgettext("sessions", "You are not authorized to see the content."))
    |> redirect(to: Routes.session_path(conn, :new))
    |> halt()
  end
end
