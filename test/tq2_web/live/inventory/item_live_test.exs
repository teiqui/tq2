defmodule Tq2Web.Inventory.ItemLiveTest do
  use Tq2Web.ConnCase

  import Tq2.Fixtures, only: [create_item: 0, init_test_session: 1]
  import Phoenix.LiveViewTest

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          live(conn, Routes.item_path(conn, :new)),
          live(conn, Routes.item_path(conn, :edit, "1"))
        ],
        fn {:error, {:redirect, %{to: path}}} ->
          assert path =~ Routes.root_path(conn, :index)
        end
      )
    end
  end

  describe "render" do
    setup [:init_test_session]

    test "disconnected and connected render new", %{conn: conn} do
      path = Routes.item_path(conn, :new)
      {:ok, item_live, html} = live(conn, path)
      content = render(item_live)

      assert html =~ "New item"
      assert content =~ "New item"
      refute html =~ "Complete with info about the item"
      refute content =~ "Complete with info about the item"
    end

    test "disconnected and connected render edit", %{conn: conn} do
      item = create_item()
      path = Routes.item_path(conn, :edit, item)
      {:ok, item_live, html} = live(conn, path)
      content = render(item_live)

      assert html =~ "Edit item"
      assert content =~ "Edit item"
    end

    test "disconnected and connected render new with tour", %{conn: conn} do
      path = Routes.item_path(conn, :new, tour: "new_item")
      {:ok, item_live, html} = live(conn, path)
      content = render(item_live)

      assert html =~ "Complete with info about the item"
      assert content =~ "Complete with info about the item"
    end

    test "validate event", %{conn: conn} do
      path = Routes.item_path(conn, :new)
      {:ok, item_live, _html} = live(conn, path)

      assert item_live
             |> form("form", %{item: %{price: "xyz"}})
             |> render_change() =~ "phx-feedback-for=\"item-form_price\">is invalid"
    end

    test "cancel entry event", %{conn: conn} do
      path = Routes.item_path(conn, :new)
      {:ok, item_live, _html} = live(conn, path)
      content = render(item_live)

      assert content =~ "Upload image"
      refute content =~ "test.png"

      image = image_input(item_live)

      assert {:ok, %{entries: _entries}} = preflight_upload(image)
      assert render(item_live) =~ "test.png"

      item_live
      |> element("[phx-click=\"cancel-entry\"]")
      |> render_click()

      refute render(item_live) =~ "test.png"
    end

    test "image upload on create", %{conn: conn, session: session} do
      path = Routes.item_path(conn, :new)
      {:ok, item_live, _html} = live(conn, path)

      assert render(item_live) =~ "Upload image"

      image = image_input(item_live)

      assert render_upload(image, "test.png") =~ "100%"

      result =
        item_live
        |> form("form", %{item: %{name: "New name", price: "12", promotional_price: "11"}})
        |> render_submit()

      assert {:error, {:redirect, %{to: path}}} = result

      item_id = path |> String.replace(~r/[^\d]/, "")

      item = Tq2.Inventories.get_item!(session.account, item_id)

      assert %{file_name: "test.png"} = item.image
    end

    test "image upload on update", %{conn: conn, session: session} do
      item = create_item()
      path = Routes.item_path(conn, :edit, item)
      {:ok, item_live, _html} = live(conn, path)

      assert render(item_live) =~ item.name
      refute item.image

      image = image_input(item_live)

      assert render_upload(image, "test.png") =~ "100%"

      result =
        item_live
        |> form("form", %{item: %{name: "Updated name", price: "12", promotional_price: "11"}})
        |> render_submit()

      assert {:error, {:redirect, %{to: _path}}} = result

      item = Tq2.Inventories.get_item!(session.account, item.id)

      assert %{file_name: "test.png"} = item.image
    end

    test "save event creates", %{conn: conn} do
      path = Routes.item_path(conn, :new)
      {:ok, item_live, _html} = live(conn, path)

      result =
        item_live
        |> form("#item-form", %{item: %{name: "New item", price: "12", promotional_price: "11"}})
        |> render_submit()

      assert {:error, {:redirect, %{to: path}}} = result

      item_id = path |> String.replace(~r/[^\d]/, "")

      assert path == Routes.item_path(conn, :show, item_id)
    end

    test "save event updates", %{conn: conn, session: session} do
      item = create_item()
      path = Routes.item_path(conn, :edit, item)
      {:ok, item_live, _html} = live(conn, path)

      refute item.name == "Updated item"
      refute item.price == Money.new(1200, :ARS)
      refute item.promotional_price == Money.new(1100, :ARS)

      result =
        item_live
        |> form("#item-form", %{
          item: %{name: "Updated item", price: "12", promotional_price: "11"}
        })
        |> render_submit()

      assert {:error, {:redirect, %{to: path}}} = result
      assert path == Routes.item_path(conn, :show, item.id)

      item = Tq2.Inventories.get_item!(session.account, item.id)

      assert item.name == "Updated item"
      assert item.price == Money.new(1200, :ARS)
      assert item.promotional_price == Money.new(1100, :ARS)
    end

    test "show optional info event", %{conn: conn} do
      path = Routes.item_path(conn, :new)
      {:ok, item_live, _html} = live(conn, path)

      refute render(item_live) =~ "collapse show"

      assert item_live
             |> element("[phx-click=\"show-optional-info\"]")
             |> render_click() =~ "collapse show"
    end
  end

  defp image_input(item_live) do
    filename = Path.absname("test/support/fixtures/files/test.png")
    %{size: size, mtime: mtime} = File.stat!(filename, time: :posix)

    file_input(item_live, "#item-form", :image, [
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
