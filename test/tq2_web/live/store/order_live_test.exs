defmodule Tq2Web.Store.OrderLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_session: 1]

  @create_attrs %{
    token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
    price_type: "promotional",
    visit_id: nil,
    data: %{handing: "pickup"}
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

  def store_fixture(%{session: session}) do
    {:ok, store} =
      Tq2.Shops.create_store(session, %{
        name: "Test store",
        slug: "test_store"
      })

    %{store: %{store | account: session.account}}
  end

  def order_fixture(%{conn: conn, store: store}) do
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
    setup [:create_session, :store_fixture, :order_fixture]

    test "disconnected and connected render", %{conn: conn, order: order, store: store} do
      path = Routes.order_path(conn, :index, store, order.id)
      {:ok, order_live, html} = live(conn, path)

      assert html =~ "Thank you for your purchase!"
      assert render(order_live) =~ "Thank you for your purchase!"
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

      assert html =~ "Thank you for your purchase!"
      assert render(order_live) =~ "Thank you for your purchase!"
      assert html =~ "Pay me"
      assert html =~ "123-345-678"
    end

    @tag :skip
    test "render regular purchase" do
    end

    @tag :skip
    test "render finished promotional purchase" do
    end
  end
end
