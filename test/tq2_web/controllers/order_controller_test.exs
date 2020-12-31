defmodule Tq2Web.OrderControllerTest do
  use Tq2Web.ConnCase, assync: true
  use Tq2.Support.LoginHelper

  import Tq2.Fixtures, only: [create_order: 1]

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.order_path(conn, :index)),
          get(conn, Routes.order_path(conn, :show, "123"))
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
end
