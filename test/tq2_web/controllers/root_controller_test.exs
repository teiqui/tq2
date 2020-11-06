defmodule Tq2Web.RootControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  describe "index" do
    test "redirect to new session", %{conn: conn} do
      conn = get(conn, Routes.root_path(conn, :index))

      assert redirected_to(conn) == Routes.session_path(conn, :new)
    end

    @tag login_as: "test@user.com"
    test "redirect to user's index when logged in", %{conn: conn} do
      conn = get(conn, Routes.root_path(conn, :index))

      assert redirected_to(conn) == Routes.user_path(conn, :index)
    end
  end
end
