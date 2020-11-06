defmodule Tq2Web.AccountControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  alias Tq2.Accounts

  @create_attrs %{
    country: "ar",
    name: "some name",
    status: "active",
    time_zone: "America/Argentina/Mendoza"
  }
  @update_attrs %{
    country: "mx",
    name: "some updated name",
    status: "green",
    time_zone: "America/Argentina/Cordoba"
  }
  @invalid_attrs %{country: nil, name: nil, status: nil, time_zone: nil}

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(@create_attrs)

    account
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.account_path(conn, :index)),
          get(conn, Routes.account_path(conn, :new)),
          post(conn, Routes.account_path(conn, :create, %{})),
          get(conn, Routes.account_path(conn, :show, "123")),
          get(conn, Routes.account_path(conn, :edit, "123")),
          put(conn, Routes.account_path(conn, :update, "123", %{})),
          delete(conn, Routes.account_path(conn, :delete, "123"))
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
    test "lists all accounts", %{conn: conn} do
      Tq2.Accounts.Account
      |> Tq2.Repo.get_by!(name: "test_account")
      |> Accounts.delete_account()

      conn = get(conn, Routes.account_path(conn, :index))

      assert html_response(conn, 200) =~ "Looks like you have no accounts"
    end
  end

  describe "index" do
    setup [:create_account]

    @tag login_as: "test@user.com"
    test "lists all accounts", %{conn: conn} do
      conn = get(conn, Routes.account_path(conn, :index))

      assert html_response(conn, 200) =~ "Accounts"
    end
  end

  describe "new account" do
    @tag login_as: "test@user.com"
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.account_path(conn, :new))

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "create account" do
    @tag login_as: "test@user.com"
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.account_path(conn, :create), account: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.account_path(conn, :show, id)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.account_path(conn, :create), account: @invalid_attrs)

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "edit account" do
    setup [:create_account]

    @tag login_as: "test@user.com"
    test "renders form for editing chosen account", %{conn: conn, account: account} do
      conn = get(conn, Routes.account_path(conn, :edit, account))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update account" do
    setup [:create_account]

    @tag login_as: "test@user.com"
    test "redirects when data is valid", %{conn: conn, account: account} do
      conn = put(conn, Routes.account_path(conn, :update, account), account: @update_attrs)

      assert redirected_to(conn) == Routes.account_path(conn, :show, account)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn, account: account} do
      conn = put(conn, Routes.account_path(conn, :update, account), account: @invalid_attrs)

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "delete account" do
    setup [:create_account]

    @tag login_as: "test@user.com"
    test "deletes chosen account", %{conn: conn, account: account} do
      conn = delete(conn, Routes.account_path(conn, :delete, account))

      assert redirected_to(conn) == Routes.account_path(conn, :index)
    end
  end

  defp create_account(_) do
    account = fixture(:account)

    %{account: account}
  end
end
