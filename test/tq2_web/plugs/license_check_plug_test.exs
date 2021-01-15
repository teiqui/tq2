defmodule Tq2Web.LicenseCheckPlugTest do
  use Tq2Web.ConnCase

  import Tq2.Fixtures, only: [init_test_session: 1]

  alias Tq2.Accounts
  alias Tq2Web.Router.Helpers, as: Routes

  describe "without session" do
    test "check for license", %{conn: conn} do
      conn = get(conn, "/")

      assert redirected_to(conn) == Routes.session_path(conn, :new)
    end
  end

  describe "app subdomain" do
    setup [:init_test_session]

    test "visit apps", %{conn: conn} do
      conn = conn |> get("/apps")

      assert html_response(conn, 200)
    end

    test "visit apps with locked account", %{conn: conn, session: session} do
      {:ok, account} = Accounts.update_account(session.account, %{status: "locked"})

      conn =
        conn
        |> assign(:current_session, %{session | account: account})
        |> get("/apps")

      assert redirected_to(conn) == Routes.license_path(conn, :index)
    end

    test "visit license without double redirect", %{conn: conn, session: session} do
      {:ok, account} = Accounts.update_account(session.account, %{status: "locked"})

      conn = conn |> assign(:current_session, %{session | account: account})

      conn = get(conn, "/license")

      assert html_response(conn, 200) =~ "License"
    end
  end
end
