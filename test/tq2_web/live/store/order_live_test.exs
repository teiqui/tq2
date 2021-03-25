defmodule Tq2Web.Store.OrderLiveTest do
  use Tq2Web.ConnCase

  import Mock
  import Phoenix.LiveViewTest

  import Tq2.Fixtures,
    only: [
      app_mercado_pago_fixture: 0,
      app_wire_transfer_fixture: 0,
      conekta_app: 0,
      create_customer: 0,
      create_session: 1,
      create_user_subscription: 1,
      default_store: 0,
      transbank_app: 0,
      user_fixture: 1
    ]

  alias Tq2.Transactions.Cart

  @create_attrs %{
    token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
    price_type: "promotional",
    visit_id: nil,
    customer_id: nil,
    data: %{handing: "pickup", payment: "cash"}
  }

  setup %{conn: conn} do
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

    conn =
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}
      |> Plug.Test.init_test_session(
        token: @create_attrs.token,
        visit_id: visit.id,
        visit_timestamp: System.os_time(:second)
      )

    {:ok, %{conn: conn, store: default_store()}}
  end

  def order_fixture(%{conn: conn, store: store}) do
    token = get_session(conn, :token)
    visit_id = get_session(conn, :visit_id)

    {:ok, cart} =
      Tq2.Transactions.create_cart(store.account, %{
        @create_attrs
        | token: token,
          visit_id: visit_id,
          customer_id: create_customer().id
      })

    line_attrs = %{
      name: "some name",
      quantity: 1,
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      cart_id: cart.id,
      item: %Tq2.Inventories.Item{
        name: "some name",
        description: "some description",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        account_id: store.account.id
      }
    }

    {:ok, line} = cart |> Tq2.Transactions.create_line(line_attrs)

    {:ok, order} =
      Tq2.Sales.create_order(store.account, %{
        status: "processing",
        promotion_expires_at:
          DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
        cart_id: cart.id
      })

    %{order: %{order | cart: %{cart | lines: [line]}}}
  end

  describe "render" do
    setup [:create_session, :order_fixture]

    test "disconnected and connected render", %{conn: conn, order: order, store: store} do
      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, html} = live(conn, path)
      content = order_live |> render()

      assert html =~ "Thank you for your purchase!"
      assert html =~ "id=\"teiqui-price-modal\""
      assert content =~ "Thank you for your purchase!"
      assert content =~ "id=\"teiqui-price-modal\""
    end

    test "render payment info", %{conn: conn, session: session, order: order, store: store} do
      data = order.cart.data |> Map.from_struct() |> Map.put(:payment, "wire_transfer")
      {:ok, _} = Tq2.Transactions.update_cart(store.account, order.cart, %{data: data})

      {:ok, _} =
        Tq2.Apps.create_app(session, %{
          "name" => "wire_transfer",
          "data" => %{"description" => "Pay me", "account_number" => "123-345-678"}
        })

      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, html} = live(conn, path)

      assert html =~ "Complete your purchase"
      assert render(order_live) =~ "Complete your purchase"
      assert html =~ "Pay me"
      assert html =~ "123-345-678"
    end

    test "render regular purchase", %{conn: conn, order: order, store: store} do
      {:ok, _cart} =
        Tq2.Transactions.update_cart(store.account, order.cart, %{price_type: "regular"})

      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, html} = live(conn, path)
      content = order_live |> render()

      assert html =~ "Thank you for your purchase!"
      assert content =~ "Thank you for your purchase!"
      refute content =~ "id=\"teiqui-price-modal\""
    end

    test "ask for notifications event", %{conn: conn, order: order, store: store} do
      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, html} = live(conn, path)
      content = order_live |> render()

      refute html =~ "Do you want to receive notifications"
      refute content =~ "Do you want to receive notifications"

      assert order_live
             |> render_hook(:"ask-for-notifications") =~ "Do you want to receive notifications"
    end

    test "subscribe event", %{conn: conn, order: order, store: store} do
      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, _html} = live(conn, path)

      render_hook(order_live, :"ask-for-notifications")

      order_live
      |> element("[phx-click=\"subscribe\"]")
      |> render_click()

      assert_push_event(order_live, "subscribe", %{})
    end

    test "dismiss event", %{conn: conn, order: order, store: store} do
      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, _html} = live(conn, path)

      render_hook(order_live, :"ask-for-notifications")

      assert render(order_live) =~ "Do you want to receive notifications"

      refute order_live
             |> element("[phx-click=\"dismiss\"]")
             |> render_click() =~ "Do you want to receive notifications"
    end

    test "register event", %{conn: conn, order: order, store: store} do
      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, _html} = live(conn, path)

      render_hook(order_live, :"ask-for-notifications")

      assert render(order_live) =~ "Do you want to receive notifications"

      render_hook(order_live, :register, subscription())

      assert_push_event(order_live, "registered", %{})
      refute render(order_live) =~ "Do you want to receive notifications"
    end

    test "save comment event", %{conn: conn, order: order, store: store} do
      path = Routes.order_path(conn, :index, store, order.id)
      user = user_fixture(%Tq2.Accounts.Session{account: order.account})

      create_user_subscription(user.id)

      {:ok, order_live, html} = live(conn, path)

      assert html =~ "No messages yet"
      assert render(order_live) =~ "No messages yet"

      order_live
      |> form("#comment-form", %{comment: %{body: "Test message"}})
      |> render_submit()

      # We must test it after, so we get the broadcasted message.
      assert render(order_live) =~ "Test message"
      refute render(order_live) =~ "No messages yet"
    end

    test "render regular pending purchase create partial payment", %{
      conn: conn,
      order: order,
      store: store
    } do
      app_mercado_pago_fixture()

      cart = order.cart

      {:ok, _payment} =
        Tq2.Payments.create_payment(
          cart,
          %{status: "paid", kind: "mercado_pago", amount: Cart.pending_amount(cart)}
        )

      data =
        cart.data
        |> Tq2.Transactions.Data.from_struct()
        |> Map.put(:payment, "mercado_pago")

      {:ok, _cart} =
        Tq2.Transactions.update_cart(store.account, cart, %{price_type: "regular", data: data})

      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, html} = live(conn, path)
      content = order_live |> render()

      assert html =~ "Complete your purchase"
      assert content =~ "Complete your purchase"
      assert content =~ "Pay with MercadoPago"
      assert content =~ "Change payment method"
      refute content =~ "id=\"teiqui-price-modal\""

      cart = Tq2.Transactions.get_cart!(store.account, cart.id)

      refute Cart.paid?(cart)
      assert Enum.count(cart.payments) == 1

      attrs = %{
        "responseCode" => "OK",
        "result" => %{
          "externalUniqueNumber" => "123"
        }
      }

      mock = [create_partial_cart_preference: fn _, _, _ -> attrs end]

      with_mock Tq2.Gateways.MercadoPago, mock do
        {:error, {:redirect, %{to: _}}} =
          order_live
          |> element("[phx-click=\"pay\"]")
          |> render_click()
      end

      cart = Tq2.Transactions.get_cart!(store.account, cart.id)

      refute Cart.paid?(cart)
      assert Enum.count(cart.payments) == 2

      pending_payment = cart.payments |> Enum.find(&(&1.status == "pending"))

      assert pending_payment.amount == Cart.pending_amount(cart)
    end

    test "render regular pending purchase change payment method", %{
      conn: conn,
      order: order,
      session: session,
      store: store
    } do
      app_mercado_pago_fixture()
      app_wire_transfer_fixture()

      cart = order.cart

      data =
        cart.data
        |> Tq2.Transactions.Data.from_struct()
        |> Map.put(:payment, "mercado_pago")

      {:ok, _cart} =
        Tq2.Transactions.update_cart(store.account, cart, %{price_type: "regular", data: data})

      day_ago = DateTime.utc_now() |> Timex.shift(days: -1, hours: -1)

      {:ok, _order} = Tq2.Sales.update_order(session, order, %{promotion_expires_at: day_ago})

      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, html} = live(conn, path)
      content = order_live |> render()

      assert html =~ "Complete your purchase"
      assert content =~ "Your 24 hours period to share the discount has expired"
      assert content =~ "Complete your purchase"
      assert content =~ "Pay with MercadoPago"
      assert content =~ "Change payment method"
      refute content =~ "id=\"teiqui-price-modal\""
      refute content =~ "id=\"wire_transfer\""
      refute content =~ "id=\"mercado_pago\""

      content =
        order_live
        |> element("[phx-click=\"show-payment-methods\"]")
        |> render_click()

      assert content =~ "id=\"wire_transfer\""
      assert content =~ "id=\"mercado_pago\""
      assert content =~ ">Change<"

      content =
        order_live
        |> form("#payment", kind: "wire_transfer")
        |> render_submit()

      refute content =~ "id=\"wire_transfer\""
      refute content =~ "id=\"mercado_pago\""
      refute content =~ ">Change<"
      # Wire transfer can not be paid with button
      refute content =~ "Pay with Wire transfer"
    end

    test "MercadoPago params triggers check payment", %{
      conn: conn,
      order: order,
      store: store
    } do
      app_mercado_pago_fixture()

      cart = order.cart

      {:ok, _payment} =
        Tq2.Payments.create_payment(
          cart,
          %{
            status: "pending",
            kind: "mercado_pago",
            amount: Cart.pending_amount(cart),
            external_id: "123"
          }
        )

      mock = [
        get: fn _url, _headers ->
          body =
            Jason.encode!(%{
              "external_reference" => "123",
              "date_approved" => DateTime.utc_now(),
              "status" => "approved",
              "transaction_amount" => 100,
              "currency_id" => "ARS"
            })

          {:ok, %HTTPoison.Response{status_code: 200, body: body}}
        end
      ]

      with_mock HTTPoison, mock do
        path = Routes.order_path(conn, :index, store, order.id, external_reference: "123")

        {:error, {:live_redirect, %{to: to}}} = live(conn, path)

        assert to == Routes.order_path(conn, :index, store, order.id)
      end
    end

    test "Transbank params triggers check payment", %{
      conn: conn,
      order: order,
      store: store
    } do
      transbank_app()

      cart = order.cart

      {:ok, _payment} =
        Tq2.Payments.create_payment(
          cart,
          %{
            status: "pending",
            kind: "transbank",
            amount: Cart.pending_amount(cart),
            external_id: "123"
          }
        )

      mock = [
        confirm_preference: fn _app, _payment ->
          %{
            "responseCode" => "OK",
            "result" => %{
              "occ" => "3333",
              "externalUniqueNumber" => "123",
              "issuedAt" => System.os_time(:second)
            }
          }
        end
      ]

      with_mock Tq2.Gateways.Transbank, [:passthrough], mock do
        path = Routes.order_path(conn, :index, store, order.id, externalUniqueNumber: "123")

        {:error, {:live_redirect, %{to: to}}} = live(conn, path)

        assert to == Routes.order_path(conn, :index, store, order.id)
      end
    end

    test "Conekta params triggers check payment", %{
      conn: conn,
      order: order,
      store: store
    } do
      conekta_app()

      cart = order.cart

      {:ok, _payment} =
        Tq2.Payments.create_payment(
          cart,
          %{
            status: "pending",
            kind: "conekta",
            amount: Cart.pending_amount(cart),
            external_id: "ord_123"
          }
        )

      mock = [
        get_order: fn _app, _id ->
          %{
            "id" => "ord_123",
            "amount" => 1000,
            "currency" => "MXN",
            "payment_status" => "paid",
            "charges" => %{
              "data" => [
                %{
                  "amount" => 1000,
                  "currency" => "MXN",
                  "order_id" => "ord_123",
                  "status" => "paid",
                  "paid_at" => System.os_time(:second)
                }
              ]
            }
          }
        end
      ]

      with_mock Tq2.Gateways.Conekta, [:passthrough], mock do
        path = Routes.order_path(conn, :index, store, order.id, checkout_id: "123")

        {:error, {:live_redirect, %{to: to}}} = live(conn, path)

        assert to == Routes.order_path(conn, :index, store, order.id)
      end
    end

    test "status param hides modal", %{conn: conn, order: order, store: store} do
      path = Routes.order_path(conn, :index, store, order.id, status: true)
      {:ok, order_live, html} = live(conn, path)
      content = order_live |> render()

      assert html =~ "Thank you for your purchase!"
      refute html =~ "id=\"teiqui-price-modal\""
      assert content =~ "Thank you for your purchase!"
      refute content =~ "id=\"teiqui-price-modal\""
    end

    @tag :skip
    test "render finished promotional purchase" do
    end
  end

  defp subscription do
    %{
      "endpoint" => "https://fcm.googleapis.com/fcm/send/some_random_things",
      "keys" => %{"p256dh" => "p256dh_key", "auth" => "auth_string"}
    }
  end
end
