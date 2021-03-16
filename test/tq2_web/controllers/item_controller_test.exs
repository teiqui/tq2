defmodule Tq2Web.ItemControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  @create_attrs %{
    name: "some name",
    description: "some description",
    visibility: "visible",
    price: "40",
    promotional_price: "30",
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

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.item_path(conn, :index)),
          get(conn, Routes.item_path(conn, :show, "123")),
          delete(conn, Routes.item_path(conn, :delete, "123"))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "index" do
    setup [:item_fixture]

    @tag login_as: "test@user.com"
    test "lists all items", %{conn: conn, item: item} do
      conn = get(conn, Routes.item_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Items"
      assert response =~ item.name
      refute response =~ "Congratulations! You have created your first article."
    end

    @tag login_as: "test@user.com"
    test "search item", %{conn: conn, item: item} do
      conn = get(conn, Routes.item_path(conn, :index, search: item.name))
      response = html_response(conn, 200)

      assert response =~ "Items"
      assert response =~ item.name
      assert response =~ "value=\"#{item.name}\""
    end

    @tag login_as: "test@user.com"
    test "lists all items and shows tour message", %{conn: conn, item: item} do
      conn = get(conn, Routes.item_path(conn, :index, tour: "item_created"))
      response = html_response(conn, 200)

      assert response =~ "Items"
      assert response =~ item.name
      assert response =~ "Congratulations! You have created your first article."
    end
  end

  describe "empty index" do
    @tag login_as: "test@user.com"
    test "lists no items", %{conn: conn} do
      conn = get(conn, Routes.item_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "You have no items yet"
      refute response =~ "We&#39;ll add your first item"
    end

    @tag login_as: "test@user.com"
    test "lists no items and has tour message", %{conn: conn} do
      conn = get(conn, Routes.item_path(conn, :index, tour: "new_item"))

      assert html_response(conn, 200) =~ "We&#39;ll add your first item"
    end
  end

  describe "empty search" do
    @tag login_as: "test@user.com"
    test "lists no items", %{conn: conn} do
      conn = get(conn, Routes.item_path(conn, :index, search: "empty_search_test"))
      response = html_response(conn, 200)

      assert response =~ "There is no match for"
      assert response =~ "empty_search_test"
    end
  end

  describe "show" do
    setup [:item_fixture]

    @tag login_as: "test@user.com"
    test "show item", %{conn: conn, item: item} do
      conn = get(conn, Routes.item_path(conn, :show, item))
      response = html_response(conn, 200)

      assert response =~ item.name
    end
  end

  describe "delete item" do
    setup [:item_fixture]

    @tag login_as: "test@user.com"
    test "deletes chosen item", %{conn: conn, item: item} do
      conn = delete(conn, Routes.item_path(conn, :delete, item))

      assert redirected_to(conn) == Routes.item_path(conn, :index)
    end
  end
end
