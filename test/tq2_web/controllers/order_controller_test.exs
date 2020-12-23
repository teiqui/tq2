defmodule Tq2Web.OrderControllerTest do
  use Tq2Web.ConnCase, async: true
  use Tq2.Support.LoginHelper

  import Tq2.Fixtures, only: [create_session: 0, create_customer: 0]

  @valid_attrs %{
    status: "pending",
    cart_id: 1,
    promotion_expires_at: Timex.now() |> Timex.shift(days: 1)
  }
  @invalid_attrs %{
    status: nil,
    cart_id: nil,
    promotion_expires_at: nil
  }

  def order_fixture(_) do
    session = create_session()

    {:ok, cart} =
      Tq2.Transactions.create_cart(session.account, %{
        token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoo=",
        customer_id: create_customer().id,
        data: %{handing: "pickup"}
      })

    {:ok, item} =
      Tq2.Inventories.create_item(session, %{
        sku: "some sku",
        name: "some name",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS)
      })

    {:ok, _line} =
      Tq2.Transactions.create_line(cart, %{
        name: "some name",
        quantity: 42,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        item: item
      })

    {:ok, order} = Tq2.Sales.create_order(session.account, %{@valid_attrs | cart_id: cart.id})

    %{order: order}
  end

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
    setup [:order_fixture]

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
    setup [:order_fixture]

    @tag login_as: "test@user.com"
    test "show order", %{conn: conn, order: order} do
      conn = get(conn, Routes.order_path(conn, :show, order))
      response = html_response(conn, 200)

      assert response =~ String.capitalize(order.status)
    end
  end

  describe "edit order" do
    setup [:order_fixture]

    @tag login_as: "test@user.com"
    test "renders form for editing chosen order", %{conn: conn, order: order} do
      conn = get(conn, Routes.order_path(conn, :edit, order))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update order" do
    setup [:order_fixture]

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
