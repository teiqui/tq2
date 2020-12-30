defmodule Tq2Web.PageControllerTest do
  use Tq2Web.ConnCase

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :web_subdomain)}.lvh.me"}

    {:ok, %{conn: conn}}
  end

  describe "index" do
    test "show page", %{conn: conn} do
      conn = get(conn, Routes.page_path(conn, :index))

      assert html_response(conn, 200) =~ "Coming soon..."
    end
  end
end