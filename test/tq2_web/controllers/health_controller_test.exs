defmodule Tq2Web.HealthControllerTest do
  use Tq2Web.ConnCase, async: true

  describe "health" do
    test "get OK", %{conn: conn} do
      conn = get(conn, Routes.health_path(conn, :index))

      assert response(conn, :ok) == ""
    end
  end
end
