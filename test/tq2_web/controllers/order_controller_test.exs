defmodule Tq2Web.OrderControllerTest do
  use Tq2Web.ConnCase, assync: true
  use Tq2.Support.LoginHelper

  import Tq2.Fixtures, only: [create_order: 1, init_test_session: 1]

  @invalid_attrs %{
    status: nil,
    cart_id: nil,
    promotion_expires_at: nil
  }

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.order_path(conn, :index)),
          get(conn, Routes.order_path(conn, :show, "123")),
          get(conn, Routes.order_path(conn, :edit, "123")),
          put(conn, Routes.order_path(conn, :update, "123", %{}))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "index" do
    setup [:create_order]

    @tag login_as: "test@user.com"
    test "lists all orders", %{conn: conn, order: order} do
      conn = get(conn, Routes.order_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Orders"
      assert response =~ String.capitalize(order.status)
    end
  end

  describe "empty index" do
    @tag login_as: "test@user.com"
    test "lists no orders", %{conn: conn} do
      conn = get(conn, Routes.order_path(conn, :index))

      assert html_response(conn, 200) =~ "at this time there is none"
    end
  end

  describe "show" do
    setup [:create_order]

    @tag login_as: "test@user.com"
    test "show order", %{conn: conn, order: order} do
      conn = get(conn, Routes.order_path(conn, :show, order))
      response = html_response(conn, 200)

      assert response =~ String.capitalize(order.status)
    end
  end

  describe "edit order" do
    setup [:init_test_session, :create_order]

    @tag login_as: "test@user.com"
    test "renders form for editing chosen order", %{conn: conn, order: order} do
      # conn = init_test_session(conn)
      conn = get(conn, Routes.order_path(conn, :edit, order))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update order" do
    setup [:init_test_session, :create_order]

    @tag login_as: "test@user.com"
    test "redirects when data is valid", %{conn: conn, order: order} do
      conn = put conn, Routes.order_path(conn, :update, order), order: %{status: "completed"}

      assert redirected_to(conn) == Routes.order_path(conn, :show, order)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn, order: order} do
      conn = put conn, Routes.order_path(conn, :update, order), order: @invalid_attrs

      assert html_response(conn, 200) =~ "Update"
    end
  end
end
