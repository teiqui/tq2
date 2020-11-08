defmodule Tq2Web.HealthControllerTest do
  use Tq2Web.ConnCase, async: true

  describe "health" do
    test "get OK" do
      conn = build_conn()
      conn = get(conn, Routes.health_path(conn, :index))

      assert response(conn, :ok) == ""
    end
  end
end
