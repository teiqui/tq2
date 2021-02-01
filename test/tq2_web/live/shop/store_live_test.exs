defmodule Tq2Web.Shop.StoreLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  import Tq2.Fixtures, only: [default_store: 1, init_test_session: 1]

  def store_fixture(_) do
    %{store: default_store(%{})}
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          live(conn, Routes.store_path(conn, :index, "main"))
        ],
        fn {:error, {:redirect, %{to: path}}} ->
          assert path =~ Routes.root_path(conn, :index)
        end
      )
    end
  end

  describe "render" do
    setup [:init_test_session, :store_fixture]

    test "disconnected and connected render", %{conn: conn} do
      path = Routes.store_path(conn, :index, "main")
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      assert html =~ "Share your store link!"
      assert content =~ "Share your store link!"
    end

    test "sections render", %{conn: conn, store: store} do
      section_content = %{
        "main" => "Share your store link!",
        "general" => store.name,
        "optional" => store.data.email,
        "delivery" => store.configuration.delivery_area,
        "pickup" => store.configuration.address,
        "advanced" => store.slug
      }

      Enum.each(section_content, fn {section, expected_content} ->
        path = Routes.store_path(conn, :index, section)
        {:ok, store_live, html} = live(conn, path)
        content = render(store_live)

        assert html =~ expected_content
        assert content =~ expected_content
      end)
    end

    test "section patch", %{conn: conn, store: store} do
      path = Routes.store_path(conn, :index, "main")
      {:ok, store_live, html} = live(conn, path)
      content = render(store_live)

      assert html =~ "Share your store link!"
      assert content =~ "Share your store link!"
      refute content =~ store.name

      assert store_live
             |> render_patch(Routes.store_path(conn, :index, "general")) =~ store.name
    end

    test "save event on change", %{conn: conn, store: store} do
      path = Routes.store_path(conn, :index, "main")
      {:ok, store_live, _html} = live(conn, path)

      assert store.published

      store_live
      |> form("form", %{store: %{published: "false"}})
      |> render_change()

      store = Tq2.Shops.get_store!(store.account)

      refute store.published
    end

    test "phone prefix render", %{conn: conn, store: store} do
      data =
        store.data
        |> Map.from_struct()
        |> Map.merge(%{phone: nil, whatsapp: nil})

      default_store(%{data: data})

      path = Routes.store_path(conn, :index, "general")
      {:ok, store_live, _html} = live(conn, path)

      assert store_live
             |> element("[name=\"store[data][phone]\"]")
             |> render() =~ "value=\"+54\""

      assert store_live
             |> element("[name=\"store[data][whatsapp]\"]")
             |> render() =~ "value=\"+54\""
    end

    test "save event", %{conn: conn, store: store} do
      path = Routes.store_path(conn, :index, "general")
      {:ok, store_live, _html} = live(conn, path)
      content = render(store_live)

      assert content =~ store.name

      assert store_live
             |> form("form", %{store: %{name: "New name"}})
             |> render_submit() =~ "New name"

      store = Tq2.Shops.get_store!(store.slug)

      assert store.name == "New name"
    end

    test "cancel entry event", %{conn: conn, store: store} do
      path = Routes.store_path(conn, :index, "general")
      {:ok, store_live, _html} = live(conn, path)
      content = render(store_live)

      assert content =~ store.name
      assert content =~ "store_default_logo.svg"
      refute render(store_live) =~ "test.png"

      logo = logo_input(store_live)

      assert {:ok, %{entries: _entries}} = preflight_upload(logo)
      assert render(store_live) =~ "test.png"

      store_live
      |> element("[phx-click=\"cancel-entry\"]")
      |> render_click()

      refute render(store_live) =~ "test.png"
    end

    test "logo upload", %{conn: conn, store: store} do
      path = Routes.store_path(conn, :index, "general")
      {:ok, store_live, _html} = live(conn, path)
      content = render(store_live)

      assert content =~ store.name
      assert content =~ "store_default_logo.svg"

      logo = logo_input(store_live)

      assert render_upload(logo, "test.png") =~ "100%"

      assert store_live
             |> form("form", %{store: %{name: store.name}})
             |> render_submit() =~ "test.png"

      store = Tq2.Shops.get_store!(store.slug)

      assert %{file_name: "test.png"} = store.logo
    end

    test "created shipping", %{conn: conn, store: _store} do
      path = Routes.store_path(conn, :index, "delivery")
      {:ok, store_live, _html} = live(conn, path)
      content = render(store_live)

      assert content =~ "Anywhere"
      assert content =~ "10.00"
      assert content =~ "prepend=\"$\""
      assert content =~ "+ Add shipping"
      assert content =~ "phx-click=\"delete-shipping\""
    end

    test "default shipping", %{conn: conn, session: session, store: store} do
      config =
        store.configuration
        |> Map.from_struct()
        |> Map.put(:shippings, [])
        |> Map.put(:delivery, false)

      {:ok, _store} = Tq2.Shops.update_store(session, store, %{configuration: config})

      path = Routes.store_path(conn, :index, "delivery")
      {:ok, store_live, _html} = live(conn, path)
      content = render(store_live)

      refute content =~ "Anywhere"
      refute content =~ "10.0"
      assert content =~ "prepend=\"$\""
      assert content =~ "+ Add shipping"
      assert content =~ "phx-click=\"delete-shipping\""
    end

    test "delete shippings and see error anyway", %{conn: conn, store: store} do
      path = Routes.store_path(conn, :index, "delivery")
      {:ok, store_live, _html} = live(conn, path)

      s = store.configuration.shippings |> List.first()

      content =
        store_live
        |> element("[phx-click=\"delete-shipping\"][phx-value-id=\"#{s.id}\"]")
        |> render_click()

      assert content =~ "+ Add shipping"
      refute content =~ "phx-click=\"delete-shipping\""

      store_live
      |> form("form")
      |> render_submit()

      store_live
      |> has_element?(
        "[phx-feedback-for=\"store_configuration_shippings_0_name\"]",
        "can't be blank"
      )
    end

    test "add new shipping", %{conn: conn, store: store} do
      path = Routes.store_path(conn, :index, "delivery")
      {:ok, store_live, _html} = live(conn, path)

      store_live
      |> element("[phx-click=\"add-shipping\"]")
      |> render_click()

      config = store.configuration |> Map.from_struct()

      shipping =
        config[:shippings]
        |> List.first()
        |> Map.from_struct()

      shippings = %{
        "0" => %{
          id: shipping.id,
          name: shipping.name,
          price: Money.to_string(shipping.price)
        },
        "1" => %{name: "Near", price: "1.0"}
      }

      content =
        store_live
        |> form("form", store: %{configuration: %{shippings: shippings}})
        |> render_submit()

      assert content =~ "Near"
      assert content =~ "value=\"1.00\""

      store = Tq2.Shops.get_store!(store.account)

      assert Enum.any?(store.configuration.shippings, fn s -> s.name == "Near" end)

      # Delete persisted shipping
      store_live
      |> element("[phx-click=\"delete-shipping\"][phx-value-id=\"#{shipping.id}\"]")
      |> render_click()

      store_live |> element("form") |> render_submit()

      store = Tq2.Shops.get_store!(store.account)

      assert Enum.count(store.configuration.shippings) == 1
      assert Enum.find(store.configuration.shippings, fn s -> s.name == "Near" end)
    end
  end

  defp logo_input(store_live) do
    filename = Path.absname("test/support/fixtures/files/test.png")
    %{size: size, mtime: mtime} = File.stat!(filename, time: :posix)

    file_input(store_live, "#store-general-form", :logo, [
      %{
        last_modified: mtime * 1000,
        name: "test.png",
        content: File.read!(filename),
        size: size,
        type: "image/png"
      }
    ])
  end
end
