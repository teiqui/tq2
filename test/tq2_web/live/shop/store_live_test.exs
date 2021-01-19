defmodule Tq2Web.Shop.StoreLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_session: 0, user_fixture: 2]

  @create_attrs %{
    name: "some name",
    description: "some description",
    slug: "some_slug",
    published: true,
    logo: nil,
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
    session = create_session()

    {:ok, store} = Tq2.Shops.create_store(session, @create_attrs)

    %{store: %{store | account: session.account}}
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
    setup [:store_fixture]

    setup %{conn: conn} do
      session = create_session()
      user = user_fixture(session, %{})

      session = %{session | user: user}

      conn =
        conn
        |> Plug.Test.init_test_session(account_id: session.account.id, user_id: session.user.id)

      {:ok, %{conn: conn}}
    end

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
      |> element("form")
      |> render_change(%{store: %{"published" => "false"}})

      store = Tq2.Shops.get_store!(store.account)

      refute store.published
    end

    test "save event", %{conn: conn, store: store} do
      path = Routes.store_path(conn, :index, "general")
      {:ok, store_live, _html} = live(conn, path)
      content = render(store_live)

      assert content =~ store.name

      assert store_live
             |> element("form")
             |> render_submit(%{store: %{"name" => "New name"}}) =~ "New name"

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
             |> element("form")
             |> render_submit(%{store: %{"name" => store.name}}) =~ "test.png"

      store = Tq2.Shops.get_store!(store.slug)

      assert %{file_name: "test.png"} = store.logo
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
