defmodule Tq2Web.PageControllerTest do
  use Tq2Web.ConnCase

  setup %{conn: conn} do
    conn = %{conn | host: Application.get_env(:tq2, :web_host)}

    {:ok, %{conn: conn}}
  end

  describe "index" do
    test "show page", %{conn: conn} do
      conn = get(conn, Routes.page_path(conn, :index))

      assert content = html_response(conn, 200)
      assert content =~ "Teiqui price"
      assert content =~ "USD $3.99"
    end

    test "redirect to Argentina page", %{conn: conn} do
      # AFIP ip
      conn = %{conn | remote_ip: {200, 1, 116, 66}}
      conn = get(conn, Routes.page_path(conn, :index))

      ar_path = Routes.page_path(conn, :index, "AR")

      assert redirected_to(conn) == ar_path

      conn = get(conn, ar_path)

      assert content = html_response(conn, 200)
      assert content =~ "Teiqui price"
      assert content =~ "ARS $499"
      assert content =~ "+ applicable taxes"
    end
  end
end
