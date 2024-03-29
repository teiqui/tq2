defmodule Tq2Web.TokenControllerTest do
  use Tq2Web.ConnCase, async: true

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}

    {:ok, %{conn: conn}}
  end

  describe "token" do
    test "redirect and put new token on session", %{conn: conn} do
      conn = get(conn, Routes.token_path(conn, :show, "some_slug", "test_token", subscribe: true))

      assert redirected_to(conn) ==
               Routes.payment_path(conn, :index, "some_slug", subscribe: true)

      assert get_session(conn, :token) == "test_token"
    end
  end
end
