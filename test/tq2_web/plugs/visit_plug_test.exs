defmodule Tq2Web.VisitPlugTest do
  use Tq2Web.ConnCase

  setup %{conn: conn} do
    conn =
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "visit" do
    test "track visit", %{conn: conn} do
      path = Routes.counter_path(conn, :index, store())

      refute get_session(conn, :visit_id)

      conn =
        conn
        |> bypass_through(Tq2Web.Router, :store)
        |> get(path)

      assert get_session(conn, :visit_id)
      assert get_session(conn, :visit_timestamp)
    end

    test "track visit only once", %{conn: conn} do
      path = Routes.counter_path(conn, :index, store())

      refute get_session(conn, :visit_id)

      conn =
        conn
        |> bypass_through(Tq2Web.Router, :store)
        |> get(path)

      visit_id = get_session(conn, :visit_id)

      assert visit_id

      conn =
        conn
        |> bypass_through(Tq2Web.Router, :store)
        |> get(path)

      assert get_session(conn, :visit_id) == visit_id
    end

    test "track visit again if refresh visit is set", %{conn: conn} do
      path = Routes.counter_path(conn, :index, store(), refresh_visit: true)

      refute get_session(conn, :visit_id)

      conn =
        conn
        |> bypass_through(Tq2Web.Router, :store)
        |> get(path)

      visit_id = get_session(conn, :visit_id)

      assert visit_id

      conn =
        conn
        |> bypass_through(Tq2Web.Router, :store)
        |> get(path)

      refute get_session(conn, :visit_id) == visit_id
    end
  end

  defp store do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    store_attrs = %{
      name: "some name",
      description: "some description",
      slug: "some_slug",
      published: true,
      account_id: "1"
    }

    {:ok, store} = Tq2.Shops.create_store(session, store_attrs)

    store
  end
end
