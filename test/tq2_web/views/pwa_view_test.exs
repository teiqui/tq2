defmodule Tq2Web.PwaViewTest do
  use Tq2Web.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders service_worker.js", %{conn: conn} do
    conn = conn |> Plug.Conn.put_private(:phoenix_endpoint, Tq2Web.Endpoint)

    assert render_to_string(Tq2Web.PwaView, "service_worker.js", conn: conn) =~
             "self.addEventListener"
  end

  test "renders manifest.json", %{conn: conn} do
    conn = conn |> Plug.Conn.put_private(:phoenix_endpoint, Tq2Web.Endpoint)

    assert render_to_string(Tq2Web.PwaView, "manifest.json", conn: conn) =~
             "Teiqui, online store that doubles your sales"
  end

  test "renders offline.html", %{conn: conn} do
    conn = conn |> Plug.Conn.put_private(:phoenix_endpoint, Tq2Web.Endpoint)

    assert render_to_string(Tq2Web.PwaView, "offline.html", conn: conn) =~ "No connection"
  end
end
