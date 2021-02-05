defmodule Tq2Web.Store.TeamLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_session: 0, default_store: 1]

  def store_fixture(_) do
    store =
      default_store(%{
        logo: %Plug.Upload{
          content_type: "image/png",
          filename: "test.png",
          path: Path.absname("test/support/fixtures/files/test.png")
        }
      })

    %{store: store}
  end

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}

    {:ok, %{conn: conn}}
  end

  describe "render" do
    setup [:store_fixture]

    test "disconnected and connected render", %{conn: conn, store: store} do
      path = Routes.team_path(conn, :index, store)
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      assert html =~ store.name
      assert content =~ store.name
      assert content =~ "Nobody has orders you can join at this time."
    end

    test "load more event", %{conn: conn, store: store} do
      path = Routes.team_path(conn, :index, store)
      orders = [create_order(), create_order()]
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      assert html =~ store.name
      assert content =~ store.name
      assert content =~ "order-#{List.first(orders).id}"
      refute content =~ "order-#{List.last(orders).id}"

      content =
        store_live
        |> element("#footer")
        |> render_hook(:"load-more")

      assert content =~ "order-#{List.last(orders).id}"
      refute has_element?(store_live, "#footer")
    end
  end

  def create_customer(attrs \\ %{}) do
    rand = :random.uniform(999_999_999)

    attrs =
      Enum.into(attrs, %{
        name: "some name #{rand}",
        email: "some_#{rand}@email.com",
        phone: "555-5555-#{rand}",
        address: "some address"
      })

    {:ok, customer} = Tq2.Sales.create_customer(attrs)

    customer
  end

  defp create_order do
    session = create_session()
    referral_token = Tq2.Sales.Customer.random_token()
    rand = :random.uniform(999_999_999)
    customer = create_customer(%{tokens: [%{value: referral_token}]})

    {:ok, visit} =
      Tq2.Analytics.create_visit(%{
        slug: "test",
        token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
        referral_token: referral_token,
        utm_source: "whatsapp",
        data: %{
          ip: "127.0.0.1"
        }
      })

    {:ok, cart} =
      Tq2.Transactions.create_cart(session.account, %{
        token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoo=",
        customer_id: customer.id,
        visit_id: visit.id,
        data: %{handing: "pickup"}
      })

    {:ok, item} =
      Tq2.Inventories.create_item(session, %{
        sku: "some sku #{rand}",
        name: "some name #{rand}",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS)
      })

    {:ok, _line} =
      Tq2.Transactions.create_line(cart, %{
        name: "some name #{rand}",
        quantity: 42,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        item: item
      })

    {:ok, order} =
      Tq2.Sales.create_order(
        session.account,
        %{
          cart_id: cart.id,
          promotion_expires_at: Timex.now() |> Timex.shift(days: 1),
          status: "pending"
        }
      )

    order
  end
end
