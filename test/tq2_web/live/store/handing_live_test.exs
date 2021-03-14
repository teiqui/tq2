defmodule Tq2Web.Store.HandingLiveTest do
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
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}
      |> Plug.Test.init_test_session(
        token: @create_attrs.token,
        visit_id: visit.id,
        visit_timestamp: System.os_time(:second)
      )

    store = default_store(%{})

    {:ok, %{conn: conn, store: store}}
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
    setup [:cart_fixture]

    test "disconnected and connected render", %{conn: conn, cart: _cart, store: store} do
      path = Routes.handing_path(conn, :index, store)
      {:ok, handing_live, html} = live(conn, path)

      assert html =~ "pickup"
      assert render(handing_live) =~ "pickup"
      assert has_element?(handing_live, ".btn.btn-block.disabled")
    end

    test "save event", %{conn: conn, cart: _cart, store: store} do
      path = Routes.handing_path(conn, :index, store)
      {:ok, handing_live, _html} = live(conn, path)

      assert has_element?(handing_live, ".btn.btn-block.disabled")

      assert handing_live
             |> form("form", cart: %{data: %{handing: "pickup"}})
             |> render_change()

      refute has_element?(handing_live, ".btn.btn-block.disabled")
    end

    test "save event with delivery", %{conn: conn, cart: _cart, store: store} do
      path = Routes.handing_path(conn, :index, store)
      {:ok, handing_live, _html} = live(conn, path)

      assert has_element?(handing_live, ".btn.btn-block.disabled")

      assert handing_live
             |> form("form", cart: %{data: %{handing: "delivery"}})
             |> render_change()

      assert has_element?(handing_live, ".btn.btn-block.disabled", "Continue")

      shipping = store.configuration.shippings |> List.first()

      assert handing_live
             |> form("form", cart: %{data: %{handing: "delivery", shipping: %{id: shipping.id}}})
             |> render_change()

      assert has_element?(handing_live, ".btn.btn-block.btn-primary", "Continue")
    end

    test "redirect to counter without cart", %{conn: conn, cart: cart, store: store} do
      cart |> Ecto.Changeset.change(%{token: "1"}) |> Tq2.Repo.update!()

      path = Routes.checkout_path(conn, :index, store)

      {:error, {:live_redirect, %{to: to}}} = live(conn, path)

      assert to == Routes.counter_path(conn, :index, store)
    end

    test "render only delivery option", %{conn: conn, store: store} do
      config =
        store.configuration
        |> Tq2.Shops.Configuration.from_struct()
        |> Map.put(:pickup, false)

      store = default_store(%{configuration: config})

      path = Routes.handing_path(conn, :index, store)
      {:ok, handing_live, html} = live(conn, path)

      assert html =~ "delivery"
      assert render(handing_live) =~ "delivery"
      refute html =~ "pickup"
      refute render(handing_live) =~ "pickup"
    end
  end
end
