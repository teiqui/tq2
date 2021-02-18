defmodule Tq2Web.TokenPlugTest do
  use Tq2Web.ConnCase

  import Tq2.Fixtures, only: [default_store: 0]

  setup %{conn: conn} do
    conn =
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "token" do
    test "fetch token", %{conn: conn} do
      path = Routes.counter_path(conn, :index, default_store())

      refute get_session(conn, :token)

      conn =
        conn
        |> bypass_through(Tq2Web.Router, :store)
        |> get(path)

      assert get_session(conn, :token)
    end
  end
end
