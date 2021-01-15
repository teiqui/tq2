defmodule Tq2Web.StorePlugTest do
  use Tq2Web.ConnCase

  import Tq2.Fixtures, only: [default_store: 0]

  alias Tq2.Accounts
  alias Tq2Web.Router.Helpers, as: Routes

  setup %{conn: conn} do
    conn =
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  describe "Store" do
    setup [:store_with_license]

    test "visit store", %{conn: conn, store: store} do
      path = Routes.counter_path(conn, :index, store)
      conn = get(conn, path)

      assert html_response(conn, 200)
    end

    test "visit store with recently locked license", %{conn: conn, license: license, store: store} do
      {:ok, _} =
        Accounts.update_license(license, %{status: "locked", paid_until: Date.utc_today()})

      path = Routes.counter_path(conn, :index, store)
      conn = get(conn, path)

      assert html_response(conn, 200)
    end

    test "visit store with locked license", %{conn: conn, license: license, store: store} do
      paid_until = Date.utc_today() |> Timex.shift(days: -15)

      {:ok, _} = Accounts.update_license(license, %{status: "locked", paid_until: paid_until})

      path = Routes.counter_path(conn, :index, store)
      conn = get(conn, path)

      assert html_response(conn, 404)
    end
  end

  defp store_with_license(_) do
    store = default_store()

    {:ok, store: store, license: store.account.license}
  end
end
