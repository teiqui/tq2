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

  def fixture(:account) do
    {:ok, account} = Accounts.create_account(@create_attrs)

    account
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.account_path(conn, :index)),
          get(conn, Routes.account_path(conn, :show, "123"))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "empty index" do
    @tag login_as: "test@user.com", login_role: "admin"
    test "lists all accounts", %{conn: conn} do
      Tq2.Accounts.Account
      |> Tq2.Repo.get_by!(name: "test_account")
      |> Accounts.delete_account()

      conn = get(conn, Routes.account_path(conn, :index))

      assert html_response(conn, 200) =~ "There are no accounts yet"
    end
  end

  describe "index" do
    setup [:create_account]

    @tag login_as: "test@user.com", login_role: "admin"
    test "lists all accounts", %{conn: conn} do
      conn = get(conn, Routes.account_path(conn, :index))

      assert html_response(conn, 200) =~ "Accounts"
    end
  end

  defp create_account(_) do
    account = fixture(:account)

    %{account: account}
  end
end
