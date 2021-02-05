defmodule Tq2Web.TokenControllerTest do
  use Tq2Web.ConnCase, async: true

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}

    {:ok, %{conn: conn}}
  end

  describe "token" do
    test "redirect and put new token on session", %{conn: conn} do
      conn = get(conn, Routes.token_path(conn, :show, "some_slug", "test_token"))

      assert redirected_to(conn) == Routes.payment_path(conn, :index, "some_slug")
      assert get_session(conn, :token) == "test_token"
    end
  end
end
