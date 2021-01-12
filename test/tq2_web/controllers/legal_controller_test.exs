defmodule Tq2Web.LegalControllerTest do
  use Tq2Web.ConnCase

  setup %{conn: conn} do
    conn = %{conn | host: Application.get_env(:tq2, :web_host)}

    {:ok, %{conn: conn}}
  end

  describe "index" do
    test "show legal", %{conn: conn} do
      conn = get(conn, Routes.legal_path(conn, :index))

      assert content = html_response(conn, 200)
      assert content =~ "Teiqui Commerce Policy"
    end
  end
end
