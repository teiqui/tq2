defmodule Tq2Web.Store.ItemLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_session: 0, default_store: 0]
  import Tq2Web.ItemView, only: [money: 1]

  @create_attrs %{
    name: "some name",
    description: "some description",
    visibility: "visible",
    price: Money.new(100, :ARS),
    promotional_price: Money.new(90, :ARS),
    image: %Plug.Upload{
      content_type: "image/png",
      filename: "test.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    }
  }

  def item_fixture(_) do
    {:ok, item} = create_session() |> Tq2.Inventories.create_item(@create_attrs)

    %{item: item}
  end

  def store_fixture(_) do
    %{store: default_store()}
  end

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}

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

    test "add event with promotional price", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, _html} = live(conn, path)

      counter_path = Routes.counter_path(conn, :index, store)

      assert {:error, {:live_redirect, %{kind: :push, to: ^counter_path}}} =
               item_live
               |> element("[phx-click=\"add\"][phx-value-type=\"promotional\"]")
               |> render_click()
    end

    test "add event with regular price", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, _html} = live(conn, path)

      item_live
      |> element("[phx-click=\"add\"][phx-value-type=\"regular\"]")
      |> render_click()

      assert_push_event(item_live, "showModal", %{})

      counter_path = Routes.counter_path(conn, :index, store)

      assert {:error, {:live_redirect, %{kind: :push, to: ^counter_path}}} =
               item_live
               |> element("[phx-click=\"add\"][phx-value-type=\"regular\"]")
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

    test "change price type event", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, _html} = live(conn, path)

      item_live
      |> element("[phx-click=\"add\"][phx-value-type=\"regular\"]")
      |> render_click()

      assert has_element?(item_live, ".btn:not([disabled])", money(item.price))
      assert has_element?(item_live, ".btn[disabled]", money(item.promotional_price))

      item_live
      |> element("[phx-click=\"change-price-type\"]")
      |> render_click()

      assert_push_event(item_live, "hideModal", %{})

      assert has_element?(item_live, ".btn[disabled]", money(item.price))
      assert has_element?(item_live, ".btn:not([disabled])", money(item.promotional_price))
    end

    test "hide modal event", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, _html} = live(conn, path)

      item_live
      |> element("[phx-click=\"hide-modal\"]")
      |> render_click()

      assert_push_event(item_live, "hideModal", %{})

      assert has_element?(item_live, ".btn:not([disabled])", money(item.price))
      assert has_element?(item_live, ".btn:not([disabled])", money(item.promotional_price))
    end

    test "redirect event", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item)
      {:ok, item_live, _html} = live(conn, path)

      counter_path = Routes.counter_path(conn, :index, store)

      assert {:error, {:live_redirect, %{kind: :push, to: ^counter_path}}} =
               item_live
               |> render_hook("redirect")
    end

    test "back with search params", %{conn: conn, item: item, store: store} do
      path = Routes.item_path(conn, :index, store, item, %{search: "Query", category: 1})
      {:ok, item_live, _html} = live(conn, path)

      assert item_live
             |> element(
               "[data-phx-link=\"redirect\"][href=\"/some_slug?category=1&amp;search=Query\"]"
             )

      assert {:error, {:live_redirect, %{kind: :push, to: counter_path}}} =
               item_live
               |> element("[phx-click=\"add\"][phx-value-type=\"promotional\"]")
               |> render_click()

      assert counter_path == "/some_slug?category=1&search=Query"
    end
  end
end
