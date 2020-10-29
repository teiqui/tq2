defmodule Tq2Web.RootController do
  use Tq2Web, :controller

  def index(conn, _params) do
    redirect(conn, to: Routes.account_path(conn, :index))
  end
end
