defmodule Tq2Web.Dashboard.MainLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  import Tq2.Fixtures,
    only: [create_session: 0, default_store: 1, create_order: 1, user_fixture: 2]

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
      refute content =~ "On the main dashboard you&#39;ll find"
      refute content =~ unpublished_store_warning()
    end

    test "with order", %{conn: conn, session: session} do
      %{order: order} = create_order(nil)

      {:ok, order} = Tq2.Sales.update_order(session, order, %{data: %{paid: true}})
      {:ok, _} = Tq2.Sales.update_order(session, order, %{status: "completed"})

      path = Routes.dashboard_path(conn, :index)
      {:ok, main_live, html} = live(conn, path)
      content = render(main_live)

      assert html =~ "Dashboard"
      assert content =~ "Dashboard"
      refute content =~ "You have no orders yet"
      assert content =~ Tq2.Transactions.Cart.total(order.cart) |> Money.to_string(symbol: true)
    end

    test "should show tour components", %{conn: conn} do
      path = Routes.dashboard_path(conn, :index, tour: "dashboard")
      {:ok, main_live, html} = live(conn, path)
      content = render(main_live)

      assert html =~ "On the main dashboard you&#39;ll find"
      assert content =~ "On the main dashboard you&#39;ll find"
      refute content =~ "Inside More you&#39;ll find sections"

      path = Routes.dashboard_path(conn, :index, tour: "items")

      assert main_live
             |> render_patch(path) =~ "Inside More you&#39;ll find sections"
    end

    test "should show unpublished warning", %{conn: conn} do
      default_store(%{published: false})

      path = Routes.dashboard_path(conn, :index)
      {:ok, main_live, html} = live(conn, path)
      content = render(main_live)

      assert html =~ unpublished_store_warning()
      assert content =~ unpublished_store_warning()
    end

    test "ask for notifications event", %{conn: conn} do
      path = Routes.dashboard_path(conn, :index)
      {:ok, main_live, html} = live(conn, path)
      content = main_live |> render()

      refute html =~ "Do you want to receive notifications"
      refute content =~ "Do you want to receive notifications"

      assert main_live
             |> render_hook(:"ask-for-notifications") =~ "Do you want to receive notifications"
    end

    test "subscribe event", %{conn: conn} do
      path = Routes.dashboard_path(conn, :index)
      {:ok, main_live, _html} = live(conn, path)

      render_hook(main_live, :"ask-for-notifications")

      main_live
      |> element("[phx-click=\"subscribe\"]")
      |> render_click()

      assert_push_event(main_live, "subscribe", %{})
    end

    test "dismiss event", %{conn: conn} do
      path = Routes.dashboard_path(conn, :index)
      {:ok, main_live, _html} = live(conn, path)

      render_hook(main_live, :"ask-for-notifications")

      assert render(main_live) =~ "Do you want to receive notifications"

      refute main_live
             |> element("[phx-click=\"dismiss\"]")
             |> render_click() =~ "Do you want to receive notifications"
    end

    test "register event", %{conn: conn} do
      path = Routes.dashboard_path(conn, :index)
      {:ok, main_live, _html} = live(conn, path)

      render_hook(main_live, :"ask-for-notifications")

      assert render(main_live) =~ "Do you want to receive notifications"

      render_hook(main_live, :register, subscription())

      assert_push_event(main_live, "registered", %{})
      refute render(main_live) =~ "Do you want to receive notifications"
    end

    defp unpublished_store_warning do
      "Your store is disabled. <u><a class=\"text-reset\" href=\"/store/edit/main\">Activate it</a></u> and start receiving orders!"
    end
  end

  defp subscription do
    %{
      "endpoint" => "https://fcm.googleapis.com/fcm/send/some_random_things",
      "keys" => %{"p256dh" => "p256dh_key", "auth" => "auth_string"}
    }
  end
end
