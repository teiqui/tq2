defmodule Tq2Web.Store.PaymentLiveTest do
  use Tq2Web.ConnCase

  import Mock
  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [app_mercado_pago_fixture: 0, default_store: 0]

  alias Tq2.Transactions.Cart
  alias Tq2.Payments

  @create_attrs %{
    token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
    price_type: "promotional",
    visit_id: nil,
    customer_id: nil,
    data: %{handing: "pickup"}
  }

  @referral_token "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4="

  setup %{conn: conn} do
    {:ok, visit} =
      Tq2.Analytics.create_visit(%{
        slug: "test",
        token: @create_attrs.token,
        referral_token: @referral_token,
        utm_source: "whatsapp",
        data: %{
          ip: "127.0.0.1"
        }
      })

    conn =
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      |> Plug.Test.init_test_session(
        token: @create_attrs.token,
        visit_id: visit.id,
        visit_timestamp: System.os_time(:second)
      )

    {:ok, %{conn: conn}}
  end

  def store_fixture(_) do
    %{store: default_store()}
  end

  def cart_fixture(%{conn: conn, store: store}) do
    token = get_session(conn, :token)
    visit_id = get_session(conn, :visit_id)

    {:ok, customer} =
      Tq2.Sales.create_customer(%{
        "name" => "some name",
        "email" => "some@email.com",
        "phone" => "555-5555",
        "address" => "some address",
        "tokens" => [%{"value" => @create_attrs.token}]
      })

    {:ok, cart} =
      Tq2.Transactions.create_cart(store.account, %{
        @create_attrs
        | token: token,
          customer_id: customer.id,
          visit_id: visit_id
      })

    line_attrs = %{
      name: "some name",
      quantity: 1,
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      cost: Money.new(80, :ARS),
      cart_id: cart.id,
      item: %Tq2.Inventories.Item{
        sku: "some sku",
        name: "some name",
        description: "some description",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        account_id: store.account.id
      }
    }

    {:ok, line} = cart |> Tq2.Transactions.create_line(line_attrs)

    %{cart: %{cart | customer: customer, lines: [line]}}
  end

  def order_fixture(%{conn: conn, store: store}) do
    visit_id = get_session(conn, :visit_id)

    {:ok, customer} =
      Tq2.Sales.create_customer(%{
        "name" => "some other name",
        "email" => "some_other@email.com",
        "phone" => "555-7777",
        "address" => "some other address",
        "tokens" => [%{"value" => @referral_token}]
      })

    {:ok, cart} =
      Tq2.Transactions.create_cart(store.account, %{
        @create_attrs
        | token: @referral_token,
          customer_id: customer.id,
          visit_id: visit_id
      })

    line_attrs = %{
      name: "some other name",
      quantity: 1,
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      cost: Money.new(80, :ARS),
      cart_id: cart.id,
      item: %Tq2.Inventories.Item{
        sku: "some other sku",
        name: "some other name",
        description: "some other description",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        account_id: store.account.id
      }
    }

    {:ok, line} = cart |> Tq2.Transactions.create_line(line_attrs)

    {:ok, order} =
      Tq2.Sales.create_order(store.account, %{
        status: "processing",
        promotion_expires_at:
          DateTime.utc_now()
          |> DateTime.add(500, :second)
          |> DateTime.truncate(:second)
          |> DateTime.to_iso8601(),
        cart_id: cart.id
      })

    %{order: %{order | cart: %{cart | lines: [line]}}}
  end

  describe "render" do
    setup [:store_fixture, :cart_fixture]

    test "disconnected and connected render", %{conn: conn, cart: _cart, store: store} do
      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, html} = live(conn, path)

      assert html =~ "cash"
      assert render(payment_live) =~ "cash"
      assert has_element?(payment_live, ".btn[disabled]")
    end

    test "update event", %{conn: conn, cart: _cart, store: store} do
      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> form("form", %{kind: "cash"})
      |> render_change()

      refute has_element?(payment_live, ".btn[disabled]")
      assert has_element?(payment_live, ".collapse.show", "Your order must be paid")
    end

    test "change kind to mercado_pago", %{conn: conn, store: store} do
      app_mercado_pago_fixture()

      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      assert payment_live
             |> form("form", %{kind: "mercado_pago"})
             |> render_change()

      refute has_element?(payment_live, ".btn[disabled]")
      assert has_element?(payment_live, ".collapse.show", "Pay with MercadoPago")
    end

    test "save event", %{conn: conn, cart: _cart, store: store} do
      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> form("form", %{kind: "cash"})
      |> render_change()

      response =
        payment_live
        |> form("form", %{})
        |> render_submit()

      assert {:error, {:live_redirect, %{kind: :push, to: to}}} = response

      order_id = String.replace(to, ~r/\D/, "")

      assert Routes.order_path(conn, :index, store, order_id) == to
    end

    test "save event with referral", %{conn: conn, cart: _cart, store: store} do
      %{order: parent_order} = order_fixture(%{conn: conn, store: store})
      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> form("form", %{kind: "cash"})
      |> render_change()

      response =
        payment_live
        |> form("form", %{})
        |> render_submit()

      assert {:error, {:live_redirect, %{kind: :push, to: to}}} = response

      order_id = String.replace(to, ~r/\D/, "")

      order =
        store.account
        |> Tq2.Sales.get_order!(order_id)
        |> Tq2.Repo.preload(:parents)

      assert Routes.order_path(conn, :index, store, order.id) == to

      assert List.first(order.parents).id == parent_order.id
    end

    test "save event with redirect to mp", %{conn: conn, store: store} do
      app_mercado_pago_fixture()

      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> form("form", %{kind: "mercado_pago"})
      |> render_change()

      payment = %{
        "id" => 123,
        "external_reference" => Ecto.UUID.generate(),
        "init_point" => "https://mp.com/123"
      }

      with_mock HTTPoison, mock_post_with(payment) do
        response =
          payment_live
          |> form("form", %{})
          |> render_submit()

        assert {:error, {:redirect, %{to: to}}} = response
        assert "https://mp.com/123" == to
      end
    end

    test "save event with mp error", %{conn: conn, store: store} do
      app_mercado_pago_fixture()

      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> form("form", %{kind: "mercado_pago"})
      |> render_change()

      payment = %{
        "message" => "Invalid credentials"
      }

      with_mock HTTPoison, mock_post_with(payment) do
        payment_live
        |> form("form", %{})
        |> render_submit()

        assert has_element?(payment_live, ".collapse.show", "Pay with MercadoPago")
      end
    end

    test "save event with redirect to mp without create", %{conn: conn, cart: cart, store: store} do
      app_mercado_pago_fixture()

      {:ok, _payment} =
        Payments.create_payment(cart, %{
          kind: "mercado_pago",
          status: "pending",
          amount: Cart.total(cart),
          external_reference: Ecto.UUID.generate(),
          gateway_data: %{
            "id" => 123,
            "external_reference" => Ecto.UUID.generate(),
            "init_point" => "https://mp.com/123"
          }
        })

      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> form("form", %{kind: "mercado_pago"})
      |> render_change()

      response =
        payment_live
        |> form("form", %{})
        |> render_submit()

      assert {:error, {:redirect, %{to: to}}} = response
      assert "https://mp.com/123" == to
    end

    test "mount with paid cart", %{conn: conn, cart: cart, store: store} do
      {:ok, _payment} =
        Payments.create_payment(cart, %{
          kind: "mercado_pago",
          status: "paid",
          amount: Cart.total(cart)
        })

      path = Routes.payment_path(conn, :index, store)
      assert {:error, {:live_redirect, %{to: to}}} = live(conn, path)

      order_id = String.replace(to, ~r/\D/, "")

      assert Routes.order_path(conn, :index, store, order_id) == to
    end

    defp mock_post_with(%{} = body, code \\ 201) do
      json_body = body |> Jason.encode!()

      [
        post: fn _url, _params, _headers ->
          {:ok, %HTTPoison.Response{status_code: code, body: json_body}}
        end
      ]
    end
  end
end
