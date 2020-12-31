defmodule Tq2Web.Order.PaymentsComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_customer: 0, init_test_session: 1]

  alias Tq2.Transactions.Cart

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

  describe "render" do
    setup [:init_test_session, :order_fixture]

    test "render", %{conn: conn, order: order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, _payment_live, html} = live(conn, path)

      assert html =~ "Cash"
      assert html =~ "Create payment"
    end

    test "update event", %{conn: conn, order: %{cart: cart} = order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, payment_live, html} = live(conn, path)

      assert html =~ "Create payment"

      pending = cart |> Cart.pending_amount() |> Money.to_string()

      content =
        payment_live
        |> element("#payments-component form")
        |> render_change(%{payment: %{amount: pending, kind: "cash"}})

      assert content =~ "Create payment"
    end

    test "save event", %{conn: conn, order: %{cart: cart} = order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, payment_live, html} = live(conn, path)

      assert html =~ "Create payment"

      pending = Cart.pending_amount(cart)

      content =
        payment_live
        |> element("#payments-component form")
        |> render_submit(%{
          payment: %{
            amount: Money.to_string(pending),
            kind: "cash"
          }
        })

      refute content =~ "Create payment"
    end

    test "save event with partial payment", %{conn: conn, order: %{cart: cart} = order} do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, payment_live, html} = live(conn, path)

      assert html =~ "Create payment"

      refute has_element?(payment_live, "#payments .card")

      amount =
        cart
        |> Cart.pending_amount()
        |> Money.multiply(0.5)

      payment_live
      |> element("#payments-component form")
      |> render_submit(%{
        payment: %{
          amount: Money.to_string(amount),
          kind: "cash"
        }
      })

      assert has_element?(payment_live, "#payments .card")

      # Check amount input for other half
      assert has_element?(
               payment_live,
               "#payments-component form [name=\"payment[amount]\"][value=\"#{
                 Money.to_string(amount)
               }\"]"
             )

      # Pay other half
      content =
        payment_live
        |> element("#payments-component form")
        |> render_submit(%{
          payment: %{
            amount: Money.to_string(amount),
            kind: "cash"
          }
        })

      refute content =~ "Create payment"
    end

    test "save event with partial payment and then delete it", %{
      conn: conn,
      order: %{cart: cart} = order
    } do
      path = Routes.order_edit_path(conn, :index, order)
      {:ok, payment_live, html} = live(conn, path)

      assert html =~ "Create payment"

      refute has_element?(payment_live, "#payments .card")

      total = Cart.pending_amount(cart)
      amount = total |> Money.multiply(0.5)

      payment_live
      |> element("#payments-component form")
      |> render_submit(%{
        payment: %{
          amount: Money.to_string(amount),
          kind: "cash"
        }
      })

      assert has_element?(payment_live, "#payments .card")

      payment_live
      |> element("#payments [phx-click=\"delete\"]")
      |> render_click()

      refute has_element?(payment_live, "#payments .card")

      # Check amount input for total
      assert has_element?(
               payment_live,
               "form [name=\"payment[amount]\"][value=\"#{Money.to_string(total)}\"]"
             )
    end
  end
end
