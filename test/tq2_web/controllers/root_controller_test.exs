defmodule Tq2Web.RootControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  describe "index" do
    test "redirect to new session", %{conn: conn} do
      conn = get(conn, Routes.root_path(conn, :index))

      assert redirected_to(conn) == Routes.session_path(conn, :new)
    end

    test "redirect to page index", %{conn: conn} do
      url_config = Tq2Web.Endpoint.config(:url)
      host = Enum.join([Application.get_env(:tq2, :web_subdomain), url_config[:host]], ".")
      conn = %{conn | host: "teiqui.com"} |> get(Routes.root_path(conn, :index))

      assert redirected_to(conn) == Routes.page_url(%URI{scheme: "https", host: host}, :index)
    end

    @tag login_as: "test@user.com"
    test "redirect to dashboard index when logged in", %{conn: conn} do
      conn = get(conn, Routes.root_path(conn, :index))

      assert redirected_to(conn) == Routes.dashboard_path(conn, :index)
    end
  end
end
