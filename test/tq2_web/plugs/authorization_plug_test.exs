defmodule Tq2Web.AuthorizationPlugTest do
  use Tq2Web.ConnCase

  alias Tq2Web.AuthorizationPlug

  @test_admin_session %Tq2.Accounts.Session{
    user: %Tq2.Accounts.User{
      role: "admin"
    }
  }

  @test_owner_session %Tq2.Accounts.Session{
    user: %Tq2.Accounts.User{
      role: "owner"
    }
  }

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "authorization" do
    test "authorize halts when no current session exists", %{conn: conn} do
      refute conn.halted

      conn = AuthorizationPlug.authorize(conn, [])

      assert conn.halted
    end

    test "authorize continues when current user has the requested role", %{conn: conn} do
      conn =
        conn
        |> assign(:current_session, @test_admin_session)
        |> AuthorizationPlug.authorize(as: :admin)

      refute conn.halted
    end

    test "authorize continues when current user has one of the requested roles", %{conn: conn} do
      conn =
        conn
        |> assign(:current_session, @test_admin_session)
        |> AuthorizationPlug.authorize(as: [:admin, :cashier])

      refute conn.halted
    end

    test "authorize halts when current user does not have the requested role", %{conn: conn} do
      conn =
        conn
        |> assign(:current_session, @test_owner_session)
        |> AuthorizationPlug.authorize(as: :admin)

      assert conn.halted
    end

    test "authorize halts when current user has none of the requested roles", %{conn: conn} do
      conn =
        conn
        |> assign(:current_session, @test_admin_session)
        |> AuthorizationPlug.authorize(as: [:cashier])

      assert conn.halted
    end
  end
end
