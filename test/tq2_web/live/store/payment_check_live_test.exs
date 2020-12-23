defmodule Tq2Web.Store.PaymentCheckLiveTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Tq2.Payments
  alias Tq2.Payments.Payment
  alias Tq2.Transactions.Cart

  @create_attrs %{
    token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
    price_type: "promotional",
    customer_id: nil
  }

  setup %{conn: conn} do
    conn =
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      |> Plug.Test.init_test_session(token: @create_attrs.token)

    {:ok, %{conn: conn}}
  end

  def store_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, store} =
      Tq2.Shops.create_store(session, %{
        name: "Test store",
        slug: "test_store",
        configuration: %{pickup: true, pickup_time_limit: "1h"}
      })

    %{store: %{store | account: account}, session: session}
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

    {:ok, cart} =
      Tq2.Transactions.create_cart(store.account, %{
        @create_attrs
        | token: token,
          customer_id: customer.id
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

    test "check and render loading", %{conn: conn, cart: cart, store: store, session: session} do
      create_mp_app(session)

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

    test "check and redirect to order", %{conn: conn, cart: cart, store: store, session: session} do
      create_mp_app(session)

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

      order = Tq2.Sales.get_order!(session.account, order_id)

      assert order.data.paid
    end

    test "check twice and redirect to order", %{
      conn: conn,
      cart: cart,
      store: store,
      session: session
    } do
      create_mp_app(session)

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

    defp create_mp_app(session) do
      {:ok, app} =
        Tq2.Apps.create_app(session, %{
          name: "mercado_pago",
          data: %{"access_token" => "123"}
        })

      app
    end
  end
end
