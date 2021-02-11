defmodule Tq2Web.PwaControllerTest do
  use Tq2Web.ConnCase, async: true

  describe "pwa" do
    test "get service worker", %{conn: conn} do
      conn = get(conn, Routes.pwa_path(conn, :service_worker))

      assert response(conn, :ok) =~ "self.addEventListener"
      assert response_content_type(conn, :javascript) == "application/javascript; charset=utf-8"
    end

    test "get manifest", %{conn: conn} do
      conn = get(conn, Routes.pwa_path(conn, :manifest))

      assert response(conn, :ok) =~ "Teiqui, online store that doubles your sales"
      assert response_content_type(conn, :json) == "application/json; charset=utf-8"
    end

    test "get offline", %{conn: conn} do
      conn = get(conn, Routes.pwa_path(conn, :offline))

      assert response(conn, :ok) =~ "No connection"
      assert response_content_type(conn, :html) == "text/html; charset=utf-8"
    end
  end
end
