defmodule Tq2Web.PageController do
  use Tq2Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
