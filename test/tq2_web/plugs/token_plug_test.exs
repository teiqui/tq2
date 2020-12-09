defmodule Tq2Web.TokenPlugTest do
  use Tq2Web.ConnCase

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "token" do
    test "fetch token", %{conn: conn} do
      conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      store = store()

      refute get_session(conn, :token)

      conn =
        conn
        |> bypass_through(Tq2Web.Router, :store)
        |> get("/#{store.slug}")

      assert get_session(conn, :token)
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
