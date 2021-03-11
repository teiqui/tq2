defmodule Tq2Web.AccountControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  import Tq2.Fixtures, only: [default_account: 1, user_fixture: 1]

  alias Tq2.Accounts

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
    setup [:default_account]

    @tag login_as: "test@user.com", login_role: "admin"
    test "lists all accounts", %{conn: conn} do
      conn = get(conn, Routes.account_path(conn, :index))

      assert html_response(conn, 200) =~ "Accounts"
    end
  end

  describe "show" do
    setup [:default_account, :create_owner]

    @tag login_as: "test@user.com", login_role: "admin"
    test "render show", %{conn: conn, account: account} do
      conn = get(conn, Routes.account_path(conn, :show, account))

      assert html_response(conn, 200) =~ account.name
    end

    @tag login_as: "test@user.com", login_role: "admin"
    test "extend license trial period", %{conn: conn, account: account} do
      today = Timex.today()

      {:ok, _license} =
        %{account.license | account: account}
        |> Accounts.update_license(%{status: "locked", paid_until: today})

      {:ok, _accoount} = account |> Accounts.update_account(%{status: "locked"})

      conn = put(conn, Routes.account_path(conn, :update, account, extend_license: true))

      assert html_response(conn, 302)
      assert redirected_to(conn) == Routes.account_path(conn, :show, account)

      account = Accounts.get_account!(account.id)
      license = Accounts.get_license!(account)
      paid_until = today |> Timex.shift(days: 14)

      assert account.status == "active"
      assert license.status == "trial"
      assert license.paid_until == paid_until
    end
  end

  def create_owner(%{account: account}) do
    owner = %Tq2.Accounts.Session{account: account} |> user_fixture()

    %{owner: owner}
  end
end
