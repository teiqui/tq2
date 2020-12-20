defmodule Tq2Web.Store.CounterLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  @create_attrs %{
    name: "some name",
    description: "some description",
    slug: "some_slug",
    published: true,
    logo: %Plug.Upload{
      content_type: "image/png",
      filename: "test.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    },
    configuration: %{
      require_email: true,
      require_phone: true,
      pickup: true,
      pickup_time_limit: "some time limit",
      address: "some address",
      delivery: true,
      delivery_area: "some delivery area",
      delivery_time_limit: "some time limit",
      pay_on_delivery: true
    },
    data: %{
      phone: "555-5555",
      email: "some@email.com",
      whatsapp: "some whatsapp",
      facebook: "some facebook",
      instagram: "some instagram"
    },
    location: %{
      latitude: "12",
      longitude: "123"
    }
  }

  def store_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, store} = Tq2.Shops.create_store(session, @create_attrs)

    %{store: store}
  end

  def items_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    items =
      Enum.map(item_attributes(), fn attrs ->
        {:ok, item} = Tq2.Inventories.create_item(session, attrs)

        item
      end)

    %{items: items}
  end

  describe "render" do
    setup [:store_fixture, :items_fixture]

    test "disconnected and connected render", %{conn: conn, store: store, items: items} do
      conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      path = Routes.counter_path(conn, :index, store)
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      assert html =~ store.name
      assert content =~ store.name
      assert content =~ List.first(items).name
    end

    test "load more event", %{conn: conn, store: store, items: items} do
      conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      path = Routes.counter_path(conn, :index, store)
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      assert html =~ store.name
      assert content =~ store.name
      assert content =~ List.first(items).name
      refute content =~ List.last(items).name

      content =
        store_live
        |> element("#footer")
        |> render_hook(:"load-more")

      assert content =~ List.last(items).name
    end
  end

  defp item_attributes do
    [
      %{
        id: "1",
        sku: "123",
        name: "Chocolate",
        description: "Very good",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS)
      },
      %{
        id: "2",
        sku: "234",
        name: "Coke",
        description: "Amazing",
        visibility: "visible",
        price: Money.new(120, :ARS),
        promotional_price: Money.new(110, :ARS),
        cost: Money.new(100, :ARS)
      }
    ]
  end
end
