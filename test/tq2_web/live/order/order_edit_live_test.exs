defmodule Tq2Web.Order.OrderEditLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_customer: 0, init_test_session: 1]

  @valid_attrs %{
    cart_id: 1,
    visit_id: 1,
    promotion_expires_at: Timex.now() |> Timex.shift(days: 1),
    status: "pending"
  }

  def order_fixture(%{session: session}) do
    {:ok, visit} =
      Tq2.Analytics.create_visit(%{
        slug: "test",
        token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
        referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
        utm_source: "whatsapp",
        data: %{
          ip: "127.0.0.1"
        }
      })

    {:ok, cart} =
      Tq2.Transactions.create_cart(session.account, %{
        token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoo=",
        customer_id: create_customer().id,
        visit_id: visit.id,
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

    {:ok, line} =
      Tq2.Transactions.create_line(cart, %{
        name: "some name",
        quantity: 42,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        item: item
      })

    cart = %{cart | account: session.account, lines: [line]}

    {:ok, order} = Tq2.Sales.create_order(session.account, %{@valid_attrs | cart_id: cart.id})

    %{order: %{order | cart: cart}}
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          live(conn, Routes.order_edit_path(conn, :index, ""))
        ],
        fn {:error, {:redirect, %{to: path}}} ->
          assert path =~ Routes.root_path(conn, :index)
        end
      )
    end
  end

  describe "render" do
    setup [:init_test_session, :order_fixture]

    test "render", %{conn: conn, order: order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, _order_live, html} = live(conn, path)

      assert html =~ "Order ##{order.id}"
    end

    test "save event", %{conn: conn, order: order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, order_live, html} = live(conn, path)

      assert html =~ "Update"

      {:error, {:redirect, %{to: path}}} =
        order_live
        |> form("#order-form", %{order: %{status: "processing"}})
        |> render_submit()

      assert Routes.order_path(conn, :show, order) == path
    end

    test "save event with invalid attrs", %{conn: conn, order: order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, order_live, html} = live(conn, path)

      assert html =~ "Update"

      order_live
      |> form("#order-form")
      |> render_submit(%{order: %{status: "unknown"}})

      assert has_element?(order_live, "[phx-feedback-for=\"order-form_status\"]", "is invalid")
    end

    test "save event completed without payments", %{conn: conn, order: order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, order_live, html} = live(conn, path)

      assert html =~ "Update"

      order_live
      |> form("#order-form", %{order: %{status: "completed"}})
      |> render_submit()

      assert has_element?(
               order_live,
               "[phx-feedback-for=\"order-form_status\"]",
               "To complete an order must be fully paid."
             )
    end

    test "handle refresh order from PaymentsComponent", %{conn: conn, order: order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, order_live, html} = live(conn, path)

      assert html =~ "Create payment"
      assert has_element?(order_live, "#order-form_lock_version[value=\"#{order.lock_version}\"]")

      content =
        order_live
        |> form("#payments-component form")
        |> render_submit()

      refute content =~ "Create payment"
      assert has_element?(order_live, "#payments .card")

      assert has_element?(
               order_live,
               "#order-form_lock_version[value=\"#{order.lock_version + 1}\"]"
             )

      {:error, {:redirect, %{to: path}}} =
        order_live
        |> form("#order-form", %{order: %{status: "completed"}})
        |> render_submit()

      assert Routes.order_path(conn, :show, order) == path
    end
  end
end
