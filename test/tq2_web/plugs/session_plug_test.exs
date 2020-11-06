defmodule Tq2Web.SessionPlugTest do
  use Tq2Web.ConnCase

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, Session}
  alias Tq2Web.SessionPlug

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  def user_fixture(attrs \\ %{}) do
    account = Tq2.Repo.get_by!(Account, name: "test_account")
    session = %Session{account: account}

    user_attrs =
      Enum.into(attrs, %{
        email: "some@email.com",
        lastname: "some lastname",
        name: "some name",
        password: "123456"
      })

    {:ok, user} = Accounts.create_user(session, user_attrs)

    {%{user | password: nil}, account}
  end

  describe "session" do
    test "fetch current session", %{conn: conn} do
      {user, account} = user_fixture()

      refute conn.assigns.current_session

      login_conn =
        conn
        |> put_session(:account_id, account.id)
        |> put_session(:user_id, user.id)
        |> SessionPlug.fetch_current_session([])
        |> send_resp(:ok, "")

      next_conn = get(login_conn, "/")

      assert next_conn.assigns.current_session.user.id == user.id
      assert next_conn.assigns.current_session.account.id == account.id
    end

    test "fetch continues when current session exists", %{conn: conn} do
      refute conn.assigns.current_session

      conn =
        conn
        |> assign(:current_session, %Tq2.Accounts.Session{})
        |> SessionPlug.fetch_current_session([])

      assert conn.assigns.current_session
    end

    test "fetch no session if no user_id on session", %{conn: conn} do
      conn = SessionPlug.fetch_current_session(conn, [])

      refute conn.assigns.current_session
    end
  end

  describe "authentication" do
    test "authenticate halts when no current session exists", %{conn: conn} do
      refute conn.halted

      conn = SessionPlug.authenticate(conn, [])

      assert conn.halted
      refute get_session(conn, :previous_url)
    end

    test "authenticate continues when current session exists", %{conn: conn} do
      conn =
        conn
        |> assign(:current_session, %Tq2.Accounts.Session{})
        |> SessionPlug.authenticate([])

      refute conn.halted
    end

    test "authenticate stores request path when no current session exists", %{conn: conn} do
      refute conn.halted

      conn = SessionPlug.authenticate(%{conn | request_path: "/test"}, [])

      assert conn.halted
      assert get_session(conn, :previous_url) == "/test"
    end
  end
end
