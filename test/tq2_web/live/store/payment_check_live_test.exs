defmodule Tq2Web.Store.PaymentCheckLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [app_mercado_pago_fixture: 0, default_store: 0]

  alias Tq2.Analytics
  alias Tq2.Payments
  alias Tq2.Payments.Payment
  alias Tq2.Transactions.Cart

  @create_attrs %{
    token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
    price_type: "promotional",
    customer_id: nil,
    visit_id: nil
  }

  setup %{conn: conn} do
    {:ok, visit} =
      Analytics.create_visit(%{
        slug: "test",
        token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
        referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
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
    {:ok, customer} =
      Tq2.Sales.create_customer(%{
        "name" => "some name",
        "email" => "some@email.com",
        "phone" => "555-5555",
        "address" => "some address"
      })

    token = get_session(conn, :token)
    visit_id = get_session(conn, :visit_id)

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

  describe "render" do
    setup [:store_fixture, :cart_fixture]

    test "redirect to payments without anything to check", %{conn: conn, store: store} do
      path = Routes.payment_check_path(conn, :index, store)

      assert {:error, {:live_redirect, %{to: to}}} = live(conn, path)
      assert to == Routes.payment_path(conn, :index, store)
    end

    test "check and render loading", %{conn: conn, cart: cart, store: store} do
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

      path = Routes.payment_check_path(conn, :index, store)
      {:ok, _check_live, html} = live(conn, path)

      assert html =~ "spinner-border"
    end

    test "check and redirect to order", %{conn: conn, cart: cart, store: store} do
      app_mercado_pago_fixture()

      {:ok, _payment} =
        Payments.create_payment(cart, %{
          kind: "mercado_pago",
          status: "paid",
          amount: Cart.total(cart),
          external_reference: Ecto.UUID.generate(),
          gateway_data: %{
            "id" => 123,
            "external_reference" => Ecto.UUID.generate(),
            "init_point" => "https://mp.com/123"
          }
        })

      path = Routes.payment_check_path(conn, :index, store)

      assert {:error, {:live_redirect, %{to: to}}} = live(conn, path)

      order_id = String.replace(to, ~r/\D/, "")

      assert Routes.order_path(conn, :index, store, order_id) == to

      order = Tq2.Sales.get_order!(store.account, order_id)

      assert order.data.paid
    end

    test "check twice and redirect to order", %{
      conn: conn,
      cart: cart,
      store: store
    } do
      app_mercado_pago_fixture()

      {:ok, payment} =
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

      path = Routes.payment_check_path(conn, :index, store)
      {:ok, check_live, html} = live(conn, path)

      assert html =~ "spinner-border"

      cart |> Payment.changeset(payment, %{status: "paid"}) |> Tq2.Repo.update!()

      refute Tq2.Repo.preload(cart, :order).order

      # simulate handle_info call
      send(check_live.pid, {:timer})

      ref = Process.monitor(check_live.pid)

      to =
        receive do
          {:DOWN, ^ref, _, _, live_response} ->
            assert {_, {:live_redirect, %{to: to}}} = live_response

            to
        end

      order = Tq2.Repo.preload(cart, :order, force: true).order

      assert Routes.order_path(conn, :index, store, order.id) == to
      assert order.data.paid
    end
  end
end
