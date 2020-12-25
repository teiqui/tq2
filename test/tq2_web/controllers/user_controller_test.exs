defmodule Tq2Web.UserControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, Session}

  @create_attrs %{
    email: "some@email.com",
    lastname: "some lastname",
    name: "some name",
    password: "123456",
    role: "owner"
  }
  @update_attrs %{
    email: "new@email.com",
    lastname: "some updated lastname",
    name: "some updated name",
    role: "owner"
  }
  @invalid_attrs %{
    email: "wrong@email",
    lastname: nil,
    name: nil,
    password: "123",
    role: nil
  }

  defp fixture(:user) do
    account = Tq2.Repo.get_by!(Account, name: "test_account")
    session = %Session{account: account}

    {:ok, user} = Accounts.create_user(session, @create_attrs)

    %{user | password: nil}
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.user_path(conn, :index)),
          get(conn, Routes.user_path(conn, :new)),
          post(conn, Routes.user_path(conn, :create, %{})),
          get(conn, Routes.user_path(conn, :show, "123")),
          get(conn, Routes.user_path(conn, :edit, "123")),
          put(conn, Routes.user_path(conn, :update, "123", %{})),
          delete(conn, Routes.user_path(conn, :delete, "123"))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "empty index" do
    @tag login_as: "test@user.com"
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))

      assert html_response(conn, 200) =~ "Looks like you have no users"
    end
  end

  describe "new user" do
    @tag login_as: "test@user.com"
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :new))

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "index" do
    setup [:create_user]

    @tag login_as: "test@user.com"
    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))

      assert html_response(conn, 200) =~ "Users"
    end
  end

  describe "create user" do
    @tag login_as: "test@user.com"
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.user_path(conn, :show, id)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "edit user" do
    setup [:create_user]

    @tag login_as: "test@user.com"
    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :edit, user))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update user" do
    setup [:create_user]

    @tag login_as: "test@user.com"
    test "redirects when data is valid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)

      assert redirected_to(conn) == Routes.user_path(conn, :show, user)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "delete user" do
    setup [:create_user]

    @tag login_as: "test@user.com"
    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))

      assert redirected_to(conn) == Routes.user_path(conn, :index)
    end
  end

  defp create_user(_) do
    user = fixture(:user)

    %{user: user}
  end
end
