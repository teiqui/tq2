defmodule Tq2Web.Store.CustomerLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [default_store: 1]

  @create_attrs %{
    token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
    price_type: "promotional",
    visit_id: 1
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
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      |> Plug.Test.init_test_session(
        token: @create_attrs.token,
        visit_id: visit.id,
        visit_timestamp: System.os_time(:second)
      )

    {:ok, %{conn: conn}}
  end

  def store_fixture(_) do
    %{store: default_store(%{})}
  end

  def cart_fixture(%{conn: conn, store: store}) do
    token = get_session(conn, :token)
    visit_id = get_session(conn, :visit_id)

    {:ok, cart} =
      Tq2.Transactions.create_cart(store.account, %{
        @create_attrs
        | token: token,
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

    %{cart: %{cart | lines: [line]}}
  end

  describe "render" do
    setup [:store_fixture, :cart_fixture]

    test "disconnected and connected render", %{conn: conn, cart: _cart, store: store} do
      path = Routes.customer_path(conn, :index, store)
      {:ok, customer_live, html} = live(conn, path)

      assert html =~ "Name"
      assert render(customer_live) =~ "Name"
      assert has_element?(customer_live, ".btn.btn-block")
    end

    test "render with existing customer, then submit goes to payment", %{
      conn: conn,
      cart: cart,
      store: store
    } do
      path = Routes.customer_path(conn, :index, store)

      {:ok, customer} =
        Tq2.Sales.create_customer(%{
          "name" => "some name",
          "email" => "some@email.com",
          "phone" => "555-5555",
          "address" => "some address",
          "tokens" => [%{"value" => cart.token}]
        })

      {:ok, customer_live, html} = live(conn, path)

      assert html =~ "bi-person-circle"
      assert html =~ customer.phone
      assert render(customer_live) =~ "bi-person-circle"

      assert customer_live
             |> form("form", %{})
             |> render_submit() ==
               {:error,
                {:live_redirect, %{kind: :push, to: Routes.payment_path(conn, :index, store)}}}
    end

    test "save event with new customer", %{conn: conn, cart: cart, store: store} do
      path = Routes.customer_path(conn, :index, store)
      {:ok, customer_live, _html} = live(conn, path)

      refute render(customer_live) =~ "bi-person-circle"

      assert customer_live
             |> form("form", %{
               customer: %{
                 name: "some name",
                 email: "some@email.com",
                 phone: "555-5555",
                 address: "some address"
               }
             })
             |> render_submit() ==
               {:error,
                {:live_redirect, %{kind: :push, to: Routes.payment_path(conn, :index, store)}}}

      assert Tq2.Transactions.get_cart(store.account, cart.token).customer_id
    end

    test "save event with new customer except phone prefix", %{conn: conn, store: store} do
      conn = %{conn | remote_ip: {200, 1, 116, 66}}

      path = Routes.customer_path(conn, :index, store)
      {:ok, customer_live, _html} = live(conn, path)

      assert customer_live
             |> form("form", %{
               customer: %{
                 name: "some name",
                 email: "some@email.com",
                 phone: "+54",
                 address: "some address"
               }
             })
             |> render_submit() ==
               {:error,
                {:live_redirect, %{kind: :push, to: Routes.payment_path(conn, :index, store)}}}

      customer = Tq2.Sales.get_customer(email: "some@email.com")

      refute customer.phone
    end

    test "validate event with new customer", %{conn: conn, cart: _cart, store: store} do
      path = Routes.customer_path(conn, :index, store)
      {:ok, customer_live, _html} = live(conn, path)

      refute render(customer_live) =~ "bi-person-circle"

      assert customer_live
             |> form("form", %{customer: %{email: "invalid@email"}})
             |> render_change() =~ "phx-feedback-for=\"customer_email\">has invalid format"

      refute render(customer_live) =~ "bi-person-circle"
    end

    test "validate event with existing customer associates token", %{
      conn: conn,
      cart: _cart,
      store: store
    } do
      path = Routes.customer_path(conn, :index, store)
      {:ok, customer_live, _html} = live(conn, path)

      {:ok, customer} =
        Tq2.Sales.create_customer(%{
          "name" => "some name",
          "email" => "some@email.com",
          "phone" => "555-5555",
          "address" => "some address"
        })

      refute render(customer_live) =~ "bi-person-circle"

      assert customer_live
             |> form("form", %{customer: %{email: customer.email}})
             |> render_change() ==
               {:error,
                {:live_redirect, %{kind: :push, to: Routes.customer_path(conn, :index, store)}}}

      customer = Tq2.Repo.preload(customer, :tokens)

      assert Enum.count(customer.tokens) == 1
    end

    test "validate event with new customer and store requires", %{conn: conn, store: store} do
      requires_for_store(store)

      path = Routes.customer_path(conn, :index, store)
      {:ok, customer_live, _html} = live(conn, path)

      refute render(customer_live) =~ "bi-person-circle"

      content =
        customer_live
        |> form("form", %{customer: %{name: "some name"}})
        |> render_change()

      assert content =~ "phx-feedback-for=\"customer_address\">can&apos;t be blank"
      assert content =~ "phx-feedback-for=\"customer_email\">can&apos;t be blank"
      assert content =~ "phx-feedback-for=\"customer_phone\">can&apos;t be blank"

      refute render(customer_live) =~ "bi-person-circle"
    end

    test "render phone prefix and validate", %{conn: conn, store: store} do
      conn = %{conn | remote_ip: {200, 1, 116, 66}}

      path = Routes.customer_path(conn, :index, store)
      {:ok, customer_live, _html} = live(conn, path)

      assert customer_live
             |> element("[name=\"customer[phone]\"]")
             |> render() =~ "value=\"+54\""

      content =
        customer_live
        |> form("form", %{customer: %{name: "some name", phone: "+543"}})
        |> render_change()

      assert content =~ "phx-feedback-for=\"customer_phone\">is invalid"

      refute render(customer_live) =~ "bi-person-circle"
    end

    test "redirect to counter without cart", %{conn: conn, cart: cart, store: store} do
      cart |> Ecto.Changeset.change(%{token: "1"}) |> Tq2.Repo.update!()

      path = Routes.checkout_path(conn, :index, store)

      {:error, {:live_redirect, %{to: to}}} = live(conn, path)

      assert to == Routes.counter_path(conn, :index, store)
    end

    defp requires_for_store(%{configuration: config}) do
      config =
        config
        |> Tq2.Shops.Configuration.from_struct()
        |> Map.merge(%{
          require_email: true,
          require_phone: true,
          require_address: true
        })

      default_store(%{configuration: config})
    end
  end
end
