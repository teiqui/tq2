defmodule Tq2Web.LegalController do
  use Tq2Web, :controller

  def index(conn, _params) do
    conn
    |> put_layout("page.html")
    |> render("index.html")
  end
end
