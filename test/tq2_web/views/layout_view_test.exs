defmodule Tq2Web.LayoutViewTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.HTML.Safe, only: [to_iodata: 1]
  import Tq2.Fixtures, only: [default_store: 1, create_item: 1]
  import Tq2.Utils.Urls, only: [store_uri: 0]

  alias Tq2Web.LayoutView

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "locale" do
    assert LayoutView.locale() == "en"
  end

  test "og tags for store", %{conn: conn} do
    store =
      default_store(%{
        logo: %Plug.Upload{
          content_type: "image/png",
          filename: "test.png",
          path: Path.absname("test/support/fixtures/files/test.png")
        }
      })

    store_tags = %{conn: conn, store: store} |> meta_og_tags()
    store_url = store_uri() |> Routes.counter_url(:index, store)

    assert store_tags =~ "og:title\" content=\"Teiqui | some name\""
    assert store_tags =~ "og:site_name\" content=\"Teiqui | some name\""
    assert store_tags =~ "og:description\" content=\"some description\""
    assert store_tags =~ "og:type\" content=\"website\""
    assert store_tags =~ "og:url\" content=\"#{store_url}\""
    assert store_tags =~ "og:image\" content=\"/images/"
    assert store_tags =~ "og:image:secure_url\" content=\"/images/"
    assert store_tags =~ "og:image:alt\" content=\"Teiqui | some name\""
  end

  test "og tags for store withut image", %{conn: conn} do
    store = default_store(%{})

    store_tags = %{conn: conn, store: store} |> meta_og_tags()

    image = conn |> Routes.static_url("/images/og_store.jpg")
    store_url = store_uri() |> Routes.counter_url(:index, store)

    assert store_tags =~ "og:title\" content=\"Teiqui | some name\""
    assert store_tags =~ "og:site_name\" content=\"Teiqui | some name\""
    assert store_tags =~ "og:description\" content=\"some description\""
    assert store_tags =~ "og:type\" content=\"website\""
    assert store_tags =~ "og:url\" content=\"#{store_url}\""
    assert store_tags =~ "og:image\" content=\"#{image}\""
    assert store_tags =~ "og:image:secure_url\" content=\"#{image}\""
    assert store_tags =~ "og:image:alt\" content=\"Teiqui | some name\""
  end

  test "og tags for store item", %{conn: conn} do
    store = default_store(%{})

    item =
      create_item(%{
        image: %Plug.Upload{
          content_type: "image/png",
          filename: "test.png",
          path: Path.absname("test/support/fixtures/files/test.png")
        }
      })

    store_tags = %{conn: conn, item: item, store: store} |> meta_og_tags()
    item_url = store_uri() |> Routes.item_url(:index, store, item)

    assert store_tags =~ "og:title\" content=\"Teiqui | some name | some name\""
    assert store_tags =~ "og:site_name\" content=\"Teiqui | some name\""
    assert store_tags =~ "og:description\" content=\"some name\""
    assert store_tags =~ "og:type\" content=\"website\""
    assert store_tags =~ "og:url\" content=\"#{item_url}\""
    assert store_tags =~ "og:image\" content=\"/images/"
    assert store_tags =~ "og:image:secure_url\" content=\"/images/"
    assert store_tags =~ "og:image:alt\" content=\"Teiqui | some name | some name\""
  end

  test "og tags for store item without image", %{conn: conn} do
    item = create_item(%{})
    store = default_store(%{})

    store_tags = %{conn: conn, item: item, store: store} |> meta_og_tags()

    image = conn |> Routes.static_url("/images/og_store.jpg")
    item_url = store_uri() |> Routes.item_url(:index, store, item)

    assert store_tags =~ "og:title\" content=\"Teiqui | some name | some name\""
    assert store_tags =~ "og:site_name\" content=\"Teiqui | some name\""
    assert store_tags =~ "og:description\" content=\"some name\""
    assert store_tags =~ "og:type\" content=\"website\""
    assert store_tags =~ "og:url\" content=\"#{item_url}\""
    assert store_tags =~ "og:image\" content=\"#{image}\""
    assert store_tags =~ "og:image:secure_url\" content=\"#{image}\""
    assert store_tags =~ "og:image:alt\" content=\"Teiqui | some name | some name\""
  end

  test "og tags for app", %{conn: conn} do
    app_tags = %{conn: conn} |> meta_og_tags()

    root_url = conn |> Routes.root_url(:index)
    image = conn |> Routes.static_url("/images/og_teiqui.jpg")

    assert app_tags =~ "og:title\" content=\"Teiqui\""
    assert app_tags =~ "og:site_name\" content=\"Teiqui\""
    assert app_tags =~ "og:description\" content=\"Teiqui - Online store\""
    assert app_tags =~ "og:type\" content=\"website\""
    assert app_tags =~ "og:url\" content=\"#{root_url}\""
    assert app_tags =~ "og:image\" content=\"#{image}\""
    assert app_tags =~ "og:image:secure_url\" content=\"#{image}\""
    assert app_tags =~ "og:image:alt\" content=\"Teiqui\""
  end

  defp meta_og_tags(assigs) do
    assigs
    |> LayoutView.meta_og_tags()
    |> to_iodata()
    |> IO.iodata_to_binary()
  end
end
