defmodule Tq2Web.Store.ItemLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  @create_attrs %{
    sku: "some sku",
    name: "some name",
    description: "some description",
    visibility: "visible",
    price: Money.new(100, :ARS),
    promotional_price: Money.new(90, :ARS),
    cost: Money.new(80, :ARS),
    image: %Plug.Upload{
      content_type: "image/png",
      filename: "test.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    }
  }

  def item_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, item} = Tq2.Inventories.create_item(session, @create_attrs)

    %{item: item}
  end

  def store_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, store} =
      Tq2.Shops.create_store(session, %{
        name: "Test store",
        slug: "test_store"
      })

    %{store: store}
  end

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}

    {:ok, %{conn: conn}}
  end

  describe "render" do
    setup [:item_fixture, :store_fixture]

    test "disconnected and connected render", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, html} = live(conn, path)

      assert html =~ item.name
      assert render(item_live) =~ item.name
      assert render(item_live) =~ Money.to_string(item.promotional_price)
    end

    test "add event", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, _html} = live(conn, path)

      counter_path = Routes.counter_path(conn, :index, store)

      assert {:error, {:live_redirect, %{kind: :push, to: ^counter_path}}} =
               item_live
               |> element("[phx-click=\"add\"][phx-value-type=\"promotional\"]")
               |> render_click()
    end

    test "increase event", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, _html} = live(conn, path)

      assert has_element?(item_live, "[data-quantity]", "1")

      item_live
      |> element("[phx-click=\"increase\"]")
      |> render_click()

      assert has_element?(item_live, "[data-quantity=\"2\"]", "2")
    end

    test "decrease event", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, _html} = live(conn, path)

      item_live
      |> element("[phx-click=\"increase\"]")
      |> render_click() =~ "data-quantity=\"2\""

      item_live
      |> element("[phx-click=\"decrease\"]")
      |> render_click() =~ "data-quantity=\"1\""

      assert has_element?(item_live, "[phx-click=\"decrease\"][disabled]")
    end
  end
end
