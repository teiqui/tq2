defmodule Tq2Web.RootController do
  use Tq2Web, :controller

  import Tq2.Utils.Urls, only: [web_uri: 0]

  def index(%{assigns: %{current_session: %{user: user}}} = conn, _params)
      when is_map(user) do
    redirect(conn, to: Routes.item_path(conn, :index))
  end

  def index(%{host: "teiqui.com"} = conn, _params) do
    uri = %{web_uri() | scheme: "https"}

    redirect(conn, external: Routes.page_url(uri, :index))
  end

  def index(conn, _params) do
    redirect(conn, to: Routes.session_path(conn, :new))
  end
end
