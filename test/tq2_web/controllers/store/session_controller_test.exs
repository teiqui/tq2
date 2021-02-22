defmodule Tq2Web.Store.SessionControllerTest do
  use Tq2Web.ConnCase, async: true

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}

    {:ok, %{conn: conn}}
  end

  describe "session" do
    test "put hide price info on session", %{conn: conn} do
      conn =
        put(conn, Routes.store_dismiss_price_info_path(conn, :dismiss_price_info, "some_slug"))

      assert get_session(conn, :hide_price_info) == true
    end
  end
end
