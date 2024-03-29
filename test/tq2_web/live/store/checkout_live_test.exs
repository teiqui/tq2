defmodule Tq2Web.Store.CheckoutLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

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
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}
      |> Plug.Test.init_test_session(
        token: @create_attrs.token,
        visit_id: visit.id,
        visit_timestamp: System.os_time(:second)
      )

    {:ok, %{conn: conn}}
  end

  def store_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, store} =
      Tq2.Shops.create_store(session, %{
        name: "Test store",
        slug: "test_store",
        configuration: %{
          require_email: true,
          require_phone: true,
          pickup: true,
          pickup_time_limit: "some time limit",
          address: "some address",
          delivery: true,
          delivery_area: "some delivery area",
          delivery_time_limit: "some time limit",
          pay_on_delivery: true,
          shippings: %{"0" => %{"name" => "Anywhere", "price" => "10.00"}}
        }
      })

    %{store: %{store | account: account}}
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

    %{cart: %{cart | lines: [line]}}
  end

  describe "render" do
    setup [:store_fixture, :cart_fixture]

    test "disconnected and connected render", %{conn: conn, cart: _cart, store: store} do
      path = Routes.checkout_path(conn, :index, store)
      {:ok, checkout_live, html} = live(conn, path)

      assert html =~ "Teiqui price"
      assert render(checkout_live) =~ "Teiqui price"
      assert has_element?(checkout_live, ".btn.btn-block")
    end

    test "increase event", %{conn: conn, cart: cart, store: store} do
      path = Routes.checkout_path(conn, :index, store)
      {:ok, checkout_live, html} = live(conn, path)
      line = List.first(cart.lines)

      assert html =~ "#{line.quantity}"

      assert has_element?(
               checkout_live,
               "[data-quantity=\"#{line.id}\"]",
               to_string(line.quantity)
             )

      checkout_live
      |> element("[phx-click=\"increase\"]")
      |> render_click()

      assert has_element?(
               checkout_live,
               "[data-quantity=\"#{line.id}\"]",
               to_string(line.quantity + 1)
             )
    end

    test "decrease event", %{conn: conn, cart: cart, store: store} do
      path = Routes.checkout_path(conn, :index, store)
      {:ok, checkout_live, html} = live(conn, path)
      line = List.first(cart.lines)

      assert html =~ "#{line.quantity}"

      assert has_element?(
               checkout_live,
               "[data-quantity=\"#{line.id}\"]",
               to_string(line.quantity)
             )

      checkout_live
      |> element("[phx-click=\"increase\"]")
      |> render_click()

      assert has_element?(
               checkout_live,
               "[data-quantity=\"#{line.id}\"]",
               to_string(line.quantity + 1)
             )

      checkout_live
      |> element("[phx-click=\"decrease\"]")
      |> render_click()

      assert has_element?(
               checkout_live,
               "[data-quantity=\"#{line.id}\"]",
               to_string(line.quantity)
             )

      checkout_live
      |> element("[phx-click=\"decrease\"]")
      |> render_click()

      assert render(checkout_live) =~ "Your cart is empty."
    end

    test "render shipping and right cart total", %{conn: conn, cart: cart, store: store} do
      shipping = store.configuration.shippings |> List.first() |> Map.from_struct()

      data =
        cart.data
        |> Tq2.Transactions.Data.from_struct()
        |> Map.merge(%{handing: "delivery", shipping: shipping})

      {:ok, _cart} = Tq2.Transactions.update_cart(store.account, cart, %{data: data})

      path = Routes.checkout_path(conn, :index, store)
      {:ok, checkout_live, html} = live(conn, path)

      assert html =~ "Teiqui price"
      assert html =~ "Shipping"
      assert html =~ "Anywhere"
      assert html =~ "$10.00"
      assert html =~ "Regular price: $11.00"
      assert render(checkout_live) =~ "Teiqui price"
      assert has_element?(checkout_live, ".btn.btn-block")
      assert has_element?(checkout_live, "tfoot tr td div.text-primary", "$10.90")
    end

    test "render with handing link when no handing", %{conn: conn, cart: cart, store: store} do
      path = Routes.checkout_path(conn, :index, store)
      handing_path = Routes.handing_path(conn, :index, store)
      customer_path = Routes.customer_path(conn, :index, store)
      {:ok, checkout_live, html} = live(conn, path)

      assert html =~ handing_path
      assert render(checkout_live) =~ handing_path
      refute html =~ customer_path
      refute render(checkout_live) =~ customer_path
      refute html =~ "Step"

      data =
        cart.data
        |> Tq2.Transactions.Data.from_struct()
        |> Map.merge(%{handing: "pickup"})

      {:ok, _cart} = Tq2.Transactions.update_cart(store.account, cart, %{data: data})
      {:ok, checkout_live, html} = live(conn, path)

      refute html =~ handing_path
      refute render(checkout_live) =~ handing_path
      assert html =~ customer_path
      assert render(checkout_live) =~ customer_path
      assert html =~ "Step"
    end

    test "redirect to counter without cart", %{conn: conn, cart: cart, store: store} do
      cart |> Ecto.Changeset.change(%{token: "1"}) |> Tq2.Repo.update!()

      path = Routes.checkout_path(conn, :index, store)

      {:error, {:live_redirect, %{to: to}}} = live(conn, path)

      assert to == Routes.counter_path(conn, :index, store)
    end
  end
end
