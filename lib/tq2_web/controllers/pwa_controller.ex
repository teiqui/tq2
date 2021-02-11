defmodule Tq2Web.PwaController do
  use Tq2Web, :controller

  def service_worker(conn, _params) do
    conn
    |> put_layout(false)
    |> render("service_worker.js")
  end

  def manifest(conn, _params) do
    render(conn, "manifest.json")
  end

  def offline(conn, _params) do
    conn
    |> fetch_session()
    |> fetch_flash()
    |> put_layout({Tq2Web.LayoutView, :root})
    |> render("offline.html")
  end
end
