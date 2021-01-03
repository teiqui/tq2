defmodule Tq2Web.RootController do
  use Tq2Web, :controller

  def index(%{assigns: %{current_session: %{user: user}}} = conn, _params)
      when is_map(user) do
    redirect(conn, to: Routes.item_path(conn, :index))
  end

  def index(%{host: "teiqui.com"} = conn, _params) do
    url_config = Tq2Web.Endpoint.config(:url)
    host = Enum.join([Application.get_env(:tq2, :web_subdomain), url_config[:host]], ".")

    redirect(conn, external: Routes.page_url(%URI{scheme: "https", host: host}, :index))
  end

  def index(conn, _params) do
    redirect(conn, to: Routes.session_path(conn, :new))
  end
end
