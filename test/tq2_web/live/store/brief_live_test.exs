defmodule Tq2Web.Store.BriefLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_customer: 1, default_account: 0, default_store: 0]

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
    account = default_account()
    store = default_store()

    %{store: %{store | account: account}}
  end

  def cart_fixture(%{conn: conn, store: store}) do
    token = get_session(conn, :token)
    visit_id = get_session(conn, :visit_id)
    rand = :random.uniform(999_999_999)

    {:ok, cart} =
      Tq2.Transactions.create_cart(store.account, %{
        @create_attrs
        | token: token,
          visit_id: visit_id
      })

    line_attrs = %{
      name: "some name #{rand}",
      quantity: 1,
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      cost: Money.new(80, :ARS),
      cart_id: cart.id,
      item: %Tq2.Inventories.Item{
        sku: "some sku #{rand}",
        name: "some name #{rand}",
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

  def order_fixture(%{conn: conn, store: store}) do
    %{cart: cart} = cart_fixture(%{conn: conn, store: store})
    shipping = List.first(store.configuration.shippings)
    customer = create_customer(%{tokens: [%{value: @create_attrs.token}]})

    cart_attrs = %{
      customer_id: customer.id,
      data: %{
        handing: "delivery",
        payment: "cash",
        shipping: Map.from_struct(shipping)
      }
    }

    cart |> Ecto.Changeset.change(cart_attrs) |> Tq2.Repo.update!()

    {:ok, order} =
      Tq2.Sales.create_order(store.account, %{
        status: "processing",
        promotion_expires_at:
          DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
        cart_id: cart.id
      })

    %{order: %{order | cart: cart}}
  end

  describe "redirect" do
    setup [:store_fixture, :cart_fixture]

    test "redirect when no previous order", %{conn: conn, cart: _cart, store: store} do
      path = Routes.brief_path(conn, :index, store)

      assert {:error, {:live_redirect, %{to: to}}} = live(conn, path)
      assert to == Routes.handing_path(conn, :index, store)
    end
  end

  describe "render" do
    setup [:store_fixture, :cart_fixture, :order_fixture]

    test "renders when previous order", %{conn: conn, cart: _cart, store: store} do
      path = Routes.brief_path(conn, :index, store)
      {:ok, brief_live, html} = live(conn, path)

      assert html =~ "Delivery"
      assert html =~ "Anywhere"
      assert render(brief_live) =~ "Delivery"
      assert render(brief_live) =~ "Anywhere"
    end

    test "save", %{conn: conn, cart: _cart, store: store} do
      path = Routes.brief_path(conn, :index, store)
      {:ok, brief_live, _html} = live(conn, path)

      response =
        brief_live
        |> form("form", %{})
        |> render_submit()

      assert {:error, {:live_redirect, %{kind: :push, to: to}}} = response

      order_id = String.replace(to, ~r/\D/, "")

      assert Routes.order_path(conn, :index, store, order_id) == to
    end

    test "redirect to counter without cart", %{conn: conn, cart: cart, store: store} do
      cart |> Ecto.Changeset.change(%{token: "1"}) |> Tq2.Repo.update!()

      path = Routes.brief_path(conn, :index, store)

      {:error, {:live_redirect, %{to: to}}} = live(conn, path)

      assert to == Routes.counter_path(conn, :index, store)
    end

    test "redirect to counter on empty cart", %{conn: conn, cart: cart, store: store} do
      cart.lines |> Enum.map(&Tq2.Repo.delete!(&1))

      path = Routes.brief_path(conn, :index, store)

      {:error, {:live_redirect, %{to: to}}} = live(conn, path)

      assert to == Routes.counter_path(conn, :index, store)
    end
  end
end
