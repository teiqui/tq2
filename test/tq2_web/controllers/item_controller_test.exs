defmodule Tq2Web.ItemControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  @create_attrs %{
    sku: "some sku",
    name: "some name",
    description: "some description",
    visibility: "visible",
    price: "40",
    promotional_price: "30",
    cost: "20",
    image: %Plug.Upload{
      content_type: "image/png",
      filename: "test.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    }
  }
  @update_attrs %{
    sku: "some updated sku",
    name: "some updated name",
    description: "some updated description",
    visibility: "hidden",
    price: "50",
    promotional_price: "40",
    cost: "30",
    image: %Plug.Upload{
      content_type: "image/png",
      filename: "test_updated.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    }
  }
  @invalid_attrs %{
    sku: nil,
    name: nil,
    description: nil,
    visibility: nil,
    price: nil,
    promotional_price: nil,
    cost: nil,
    image: nil
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
          get(conn, Routes.item_path(conn, :new)),
          post(conn, Routes.item_path(conn, :create, %{})),
          get(conn, Routes.item_path(conn, :show, "123")),
          get(conn, Routes.item_path(conn, :edit, "123")),
          put(conn, Routes.item_path(conn, :update, "123", %{})),
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

  describe "new item" do
    @tag login_as: "test@user.com"
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.item_path(conn, :new))
      response = html_response(conn, 200)

      assert response =~ "Create"
      refute response =~ "Complete with info about the item"
      refute response =~ "Teiqui price must be lower than regular"
    end

    @tag login_as: "test@user.com"
    test "renders form with tour message", %{conn: conn} do
      conn = get(conn, Routes.item_path(conn, :new, tour: "new_item"))
      response = html_response(conn, 200)

      assert response =~ "Complete with info about the item"
      assert response =~ "Teiqui price must be lower than regular"
    end
  end

  describe "create item" do
    @tag login_as: "test@user.com"
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, Routes.item_path(conn, :create), item: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.item_path(conn, :show, id)
    end

    @tag login_as: "test@user.com"
    test "redirects to index when data is valid and on tour", %{conn: conn} do
      conn = post conn, Routes.item_path(conn, :create, tour: "test"), item: @create_attrs

      assert redirected_to(conn) == Routes.item_path(conn, :index, tour: "item_created")
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.item_path(conn, :create), item: @invalid_attrs

      assert html_response(conn, 200) =~ "Create"
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

  describe "edit item" do
    setup [:item_fixture]

    @tag login_as: "test@user.com"
    test "renders form for editing chosen item", %{conn: conn, item: item} do
      conn = get(conn, Routes.item_path(conn, :edit, item))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update item" do
    setup [:item_fixture]

    @tag login_as: "test@user.com"
    test "redirects when data is valid", %{conn: conn, item: item} do
      conn = put conn, Routes.item_path(conn, :update, item), item: @update_attrs

      assert redirected_to(conn) == Routes.item_path(conn, :show, item)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn, item: item} do
      conn = put conn, Routes.item_path(conn, :update, item), item: @invalid_attrs

      assert html_response(conn, 200) =~ "Update"
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
