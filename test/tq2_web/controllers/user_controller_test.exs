defmodule Tq2Web.UserControllerTest do
  use Tq2Web.ConnCase

  alias Tq2.Accounts

  @create_attrs %{
    email: "some@email.com",
    lastname: "some lastname",
    name: "some name",
    password: "123456"
  }
  @update_attrs %{
    email: "new@email.com",
    lastname: "some updated lastname",
    name: "some updated name"
  }
  @invalid_attrs %{email: "wrong@email", lastname: nil, name: nil, password: "123"}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)

    user
  end

  describe "empty index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))

      assert html_response(conn, 200) =~ "Looks like you have no users"
    end
  end

  describe "index" do
    setup [:create_user]

    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))

      assert html_response(conn, 200) =~ "Users"
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :new))

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "create user" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.user_path(conn, :show, id)

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert html_response(conn, 200) =~ @create_attrs.email
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "edit user" do
    setup [:create_user]

    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :edit, user))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update user" do
    setup [:create_user]

    test "redirects when data is valid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)

      assert redirected_to(conn) == Routes.user_path(conn, :show, user)

      conn = get(conn, Routes.user_path(conn, :show, user))

      assert html_response(conn, 200) =~ @update_attrs.email
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))

      assert redirected_to(conn) == Routes.user_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end
  end

  defp create_user(_) do
    user = fixture(:user)

    %{user: user}
  end
end
