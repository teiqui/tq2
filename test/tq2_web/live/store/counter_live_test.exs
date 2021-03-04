defmodule Tq2Web.Store.CounterLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_customer: 0, create_session: 0, default_store: 1]

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

  def items_fixture(_) do
    session = create_session()

    {:ok, candies} = Tq2.Inventories.create_category(session, %{name: "Candies"})
    {:ok, drinks} = Tq2.Inventories.create_category(session, %{name: "Drinks"})

    categories = %{
      "Chocolate" => candies,
      "Coke" => drinks
    }

    items =
      Enum.map(item_attributes(), fn attrs ->
        category = categories[attrs.name]

        create_item(session, %{attrs | category_id: category.id}, category)
      end)

    %{items: items, categories: categories}
  end

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}

    {:ok, %{conn: conn}}
  end

  describe "render" do
    setup [:store_fixture, :items_fixture]

    test "disconnected and connected render", %{conn: conn, store: store, items: items} do
      path = Routes.counter_path(conn, :index, store)
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      assert html =~ store.name
      assert content =~ store.name
      assert content =~ List.first(items).name
    end

    test "load more event", %{conn: conn, store: store, items: items} do
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
        |> render_hook("load-more")

      assert content =~ List.last(items).name
      refute has_element?(store_live, "#footer")
    end

    test "toggle categories and back to items", %{conn: conn, store: store, items: items} do
      path = Routes.counter_path(conn, :index, store)
      {:ok, store_live, html} = live(conn, path)

      assert html =~ "chevron-down"
      assert html =~ "Categories"

      content =
        store_live
        |> element("#toggle-categories")
        |> render_click()

      {[with_image], [without_image]} = items |> Enum.split_with(& &1.image)

      assert content =~ with_image.category.name
      assert content =~ without_image.category.name
      assert content =~ "chevron-up"
      assert content =~ "Categories"

      img =
        store_live
        |> element("#categories #category-#{with_image.category_id}")
        |> render()

      assert img =~ "<img"

      img =
        store_live
        |> element("#categories #category-#{without_image.category_id}")
        |> render()

      assert img =~ "<svg"

      content =
        store_live
        |> element("#toggle-categories")
        |> render_click()

      assert content =~ store.name
      assert content =~ List.first(items).name
    end

    test "change category then clean", %{conn: conn, store: store, items: items} do
      item = List.last(items)
      category = item.category
      path = Routes.counter_path(conn, :index, store, category: category.id)

      {:ok, store_live, content} = live(conn, path)

      assert content =~ item.name
      assert content =~ category.name
      refute content =~ "Categories"
      refute content =~ "#footer"

      store_live
      |> element("#toggle-categories")
      |> render_click()

      assert store_live |> has_element?("#category-#{category.id} .bg-success")

      content =
        store_live
        |> element("#show_all")
        |> render_click()

      assert content =~ List.first(items).name
    end

    test "render category with 1 or 4 images", %{conn: conn, items: [item | _], store: store} do
      category_id = item.category_id
      path = Routes.counter_path(conn, :index, store)
      session = create_session()

      attrs = %{
        name: nil,
        visibility: "visible",
        price: Money.new(120, :ARS),
        promotional_price: Money.new(110, :ARS),
        cost: Money.new(100, :ARS),
        category_id: category_id,
        image: %Plug.Upload{
          content_type: "image/png",
          filename: "test.png",
          path: Path.absname("test/support/fixtures/files/test.png")
        }
      }

      {:ok, store_live, _html} = live(conn, path)

      assert images_count(store_live, category_id) == 1

      create_item(session, %{attrs | name: "item2"})

      assert images_count(store_live, category_id) == 1

      create_item(session, %{attrs | name: "item3"})

      assert images_count(store_live, category_id) == 1

      create_item(session, %{attrs | name: "item4"})

      assert images_count(store_live, category_id) == 4
    end

    test "search items", %{conn: conn, store: store} do
      path = Routes.counter_path(conn, :index, store)
      {:ok, store_live, _html} = live(conn, path)

      {:ok, store_live, content} =
        store_live
        |> form("form", %{search: "coke"})
        |> render_submit()
        |> follow_redirect(conn)

      assert content =~ "Coke"

      {:ok, _, content} =
        store_live
        |> form("form", %{search: "choco"})
        |> render_submit()
        |> follow_redirect(conn)

      assert content =~ "Chocolate"
    end

    test "search items inside category", %{
      conn: conn,
      store: store,
      categories: %{"Chocolate" => category}
    } do
      session = create_session()

      create_item(
        session,
        %{
          name: "Other candy",
          visibility: "visible",
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS),
          category_id: category.id
        },
        category
      )

      create_item(
        session,
        %{
          name: "Other",
          visibility: "visible",
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS),
          category_id: nil
        }
      )

      path = Routes.counter_path(conn, :index, store, category: category.id)
      {:ok, store_live, content} = live(conn, path)

      assert content =~ "Chocolate"

      content =
        store_live
        |> element("#footer")
        |> render_hook("load-more")

      assert content =~ "Other candy"

      store_live
      |> form("form", %{search: "other"})
      |> render_submit()
      |> follow_redirect(conn)

      assert content =~ "Other candy"
      refute content =~ "#footer"
    end

    test "render teiqui price info and then close", %{conn: conn, store: store} do
      path = Routes.counter_path(conn, :index, store)
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      assert html =~ "Enjoy the discount making other"
      assert content =~ "Enjoy the discount making other"

      content =
        store_live
        |> element("[phx-click=\"dismiss\"][phx-value-id=\"price-info\"]")
        |> render_click()

      refute content =~ "Enjoy the discount making other"
    end

    test "should not render teiqui price info with customer", %{conn: conn, store: store} do
      customer = create_customer()

      {:ok, token} =
        Tq2.Shares.create_token(%{
          value: "hItfgIBvse62B_oZPgu6Ppp3qORvjbVCPEi9E-Poz2U=",
          customer_id: customer.id
        })

      conn = conn |> Plug.Test.init_test_session(token: token.value)
      path = Routes.counter_path(conn, :index, store)
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      refute html =~ "Enjoy the discount making other"
      refute content =~ "Enjoy the discount making other"
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
        cost: Money.new(80, :ARS),
        category_id: nil,
        image: %Plug.Upload{
          content_type: "image/png",
          filename: "test.png",
          path: Path.absname("test/support/fixtures/files/test.png")
        }
      },
      %{
        id: "2",
        sku: "234",
        name: "Coke",
        description: "Amazing",
        visibility: "visible",
        price: Money.new(120, :ARS),
        promotional_price: Money.new(110, :ARS),
        cost: Money.new(100, :ARS),
        category_id: nil
      }
    ]
  end

  defp create_item(session, attrs, category \\ nil) do
    {:ok, item} = Tq2.Inventories.create_item(session, attrs)

    %{item | category: category}
  end

  defp images_count(store_live, category_id) do
    # Open
    store_live
    |> element("#toggle-categories")
    |> render_click()

    count =
      store_live
      |> element("#category-#{category_id}")
      |> render()
      |> Floki.parse_document!()
      |> Floki.find("img")
      |> Enum.count()

    # Close
    store_live
    |> element("#toggle-categories")
    |> render_click()

    count
  end
end
