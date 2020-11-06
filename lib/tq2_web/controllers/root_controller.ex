defmodule Tq2Web.RootController do
  use Tq2Web, :controller

  def index(%{assigns: %{current_session: %{user: user}}} = conn, _params)
      when is_map(user) do
    redirect(conn, to: Routes.user_path(conn, :index))
  end

  def index(conn, _params) do
    redirect(conn, to: Routes.session_path(conn, :new))
  end
end
