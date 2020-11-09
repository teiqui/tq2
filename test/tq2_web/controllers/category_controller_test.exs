defmodule Tq2Web.CategoryControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  @create_attrs %{name: "some name", ordinal: 0}
  @update_attrs %{name: "some updated name", ordinal: 1}
  @invalid_attrs %{name: nil, ordinal: nil}

  def category_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, category} = Tq2.Inventories.create_category(session, @create_attrs)

    %{category: category}
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.category_path(conn, :index)),
          get(conn, Routes.category_path(conn, :new)),
          post(conn, Routes.category_path(conn, :create, %{})),
          get(conn, Routes.category_path(conn, :show, "123")),
          get(conn, Routes.category_path(conn, :edit, "123")),
          put(conn, Routes.category_path(conn, :update, "123", %{})),
          delete(conn, Routes.category_path(conn, :delete, "123"))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "index" do
    setup [:category_fixture]

    @tag login_as: "test@user.com"
    test "lists all categories", %{conn: conn, category: category} do
      conn = get(conn, Routes.category_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Categories"
      assert response =~ category.name
    end
  end

  describe "empty index" do
    @tag login_as: "test@user.com"
    test "lists no categories", %{conn: conn} do
      conn = get(conn, Routes.category_path(conn, :index))

      assert html_response(conn, 200) =~ "you have no categories"
    end
  end

  describe "new category" do
    @tag login_as: "test@user.com"
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.category_path(conn, :new))

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "create category" do
    @tag login_as: "test@user.com"
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, Routes.category_path(conn, :create), category: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.category_path(conn, :show, id)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.category_path(conn, :create), category: @invalid_attrs

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "show" do
    setup [:category_fixture]

    @tag login_as: "test@user.com"
    test "show category", %{conn: conn, category: category} do
      conn = get(conn, Routes.category_path(conn, :show, category))
      response = html_response(conn, 200)

      assert response =~ category.name
    end
  end

  describe "edit category" do
    setup [:category_fixture]

    @tag login_as: "test@user.com"
    test "renders form for editing chosen category", %{conn: conn, category: category} do
      conn = get(conn, Routes.category_path(conn, :edit, category))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update category" do
    setup [:category_fixture]

    @tag login_as: "test@user.com"
    test "redirects when data is valid", %{conn: conn, category: category} do
      conn = put conn, Routes.category_path(conn, :update, category), category: @update_attrs

      assert redirected_to(conn) == Routes.category_path(conn, :show, category)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn, category: category} do
      conn = put conn, Routes.category_path(conn, :update, category), category: @invalid_attrs

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "delete category" do
    setup [:category_fixture]

    @tag login_as: "test@user.com"
    test "deletes chosen category", %{conn: conn, category: category} do
      conn = delete(conn, Routes.category_path(conn, :delete, category))

      assert redirected_to(conn) == Routes.category_path(conn, :index)
    end
  end
end
