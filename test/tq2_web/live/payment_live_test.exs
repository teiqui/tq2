defmodule Tq2Web.PaymentLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  @create_attrs %{
    token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
    price_type: "promotional"
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
        slug: "test_store"
      })

    %{store: %{store | account: account}}
  end

  def cart_fixture(%{conn: conn, store: store}) do
    token = get_session(conn, :token)
    {:ok, cart} = Tq2.Transactions.create_cart(store.account, %{@create_attrs | token: token})

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
      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, html} = live(conn, path)

      assert html =~ "cash"
      assert render(payment_live) =~ "cash"
      assert has_element?(payment_live, ".btn[disabled]")
    end

    test "save event", %{conn: conn, cart: _cart, store: store} do
      path = Routes.payment_path(conn, :index, store)
      {:ok, payment_live, _html} = live(conn, path)

      assert has_element?(payment_live, ".btn[disabled]")

      assert payment_live
             |> element("form")
             |> render_change(%{"kind" => "cash"})

      refute has_element?(payment_live, ".btn[disabled]")
    end
  end
end
