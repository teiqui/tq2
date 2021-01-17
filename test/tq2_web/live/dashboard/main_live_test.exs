defmodule Tq2Web.Dashboard.MainLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  import Tq2.Fixtures,
    only: [create_session: 0, default_store: 0, create_order: 1, user_fixture: 2]

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          live(conn, Routes.dashboard_path(conn, :index))
        ],
        fn {:error, {:redirect, %{to: path}}} ->
          assert path =~ Routes.root_path(conn, :index)
        end
      )
    end
  end

  describe "render" do
    setup %{conn: conn} do
      session = create_session()
      user = user_fixture(session, %{})
      _store = default_store()

      session = %{session | user: user}

      conn =
        conn
        |> Plug.Test.init_test_session(account_id: session.account.id, user_id: session.user.id)

      {:ok, %{conn: conn, session: session}}
    end

    test "disconnected and connected render", %{conn: conn} do
      path = Routes.dashboard_path(conn, :index)
      {:ok, main_live, html} = live(conn, path)
      content = render(main_live)

      assert html =~ "Dashboard"
      assert content =~ "Dashboard"
      assert content =~ "You have no orders yet"
    end

    test "with order", %{conn: conn, session: session} do
      %{order: order} = create_order(nil)

      {:ok, _} = Tq2.Sales.update_order(session, order, %{status: "completed"})

      path = Routes.dashboard_path(conn, :index)
      {:ok, main_live, html} = live(conn, path)
      content = render(main_live)

      assert html =~ "Dashboard"
      assert content =~ "Dashboard"
      refute content =~ "You have no orders yet"
      assert content =~ Tq2.Transactions.Cart.total(order.cart) |> Money.to_string(symbol: true)
    end
  end
end
