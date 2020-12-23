defmodule Tq2Web.Store.PaymentLiveTest do
  use Tq2Web.ConnCase, async: true

  import Mock
  import Phoenix.LiveViewTest
  alias Tq2.Transactions.Cart
  alias Tq2.Payments

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
        configuration: %{pickup: true, pickup_time_limit: "3hs"}
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
      |> element("form")
      |> render_change(%{"kind" => "cash"})

      refute has_element?(payment_live, ".btn[disabled]")
      assert has_element?(payment_live, ".collapse.show", "Your order must be paid")
    end

    test "change kind to mercado_pago", %{conn: conn, store: store, session: session} do
      create_mp_app(session)

      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      assert payment_live
             |> element("form")
             |> render_change(%{"kind" => "mercado_pago"})

      refute has_element?(payment_live, ".btn[disabled]")
      assert has_element?(payment_live, ".collapse.show", "Pay with MercadoPago")
    end

    test "save event", %{conn: conn, cart: _cart, store: store} do
      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> element("form")
      |> render_change(%{"kind" => "cash"})

      response =
        payment_live
        |> element("form")
        |> render_submit(%{})

      assert {:error, {:live_redirect, %{kind: :push, to: to}}} = response

      order_id = String.replace(to, ~r/\D/, "")

      assert Routes.order_path(conn, :index, store, order_id) == to
    end

    test "save event with redirect to mp", %{conn: conn, store: store, session: session} do
      create_mp_app(session)

      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> element("form")
      |> render_change(%{"kind" => "mercado_pago"})

      payment = %{
        "id" => 123,
        "external_reference" => Ecto.UUID.generate(),
        "init_point" => "https://mp.com/123"
      }

      with_mock HTTPoison, mock_post_with(payment) do
        response =
          payment_live
          |> element("form")
          |> render_submit(%{})

        assert {:error, {:redirect, %{to: to}}} = response
        assert "https://mp.com/123" == to
      end
    end

    test "save event with mp error", %{conn: conn, store: store, session: session} do
      create_mp_app(session)

      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> element("form")
      |> render_change(%{"kind" => "mercado_pago"})

      payment = %{
        "message" => "Invalid credentials"
      }

      with_mock HTTPoison, mock_post_with(payment) do
        payment_live
        |> element("form")
        |> render_submit(%{})

        assert has_element?(payment_live, ".collapse.show", "Pay with MercadoPago")
      end
    end

    test "save event with redirect to mp without create", %{
      conn: conn,
      cart: cart,
      store: store,
      session: session
    } do
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

      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      payment_live
      |> element("form")
      |> render_change(%{"kind" => "mercado_pago"})

      response =
        payment_live
        |> element("form")
        |> render_submit(%{})

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

    defp create_mp_app(session) do
      {:ok, app} =
        Tq2.Apps.create_app(session, %{
          name: "mercado_pago",
          data: %{"access_token" => "123"}
        })

      app
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
