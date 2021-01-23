defmodule Tq2Web.Registration.TourLiveTest do
  use Tq2Web.ConnCase

  import Tq2.Fixtures, only: [create_session: 0, user_fixture: 2]
  import Phoenix.LiveViewTest

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          live(conn, Routes.tour_path(conn, :index))
        ],
        fn {:error, {:redirect, %{to: path}}} ->
          assert path =~ Routes.root_path(conn, :index)
        end
      )
    end
  end

  describe "render" do
    setup %{conn: conn} do
      session = create_session()
      user = user_fixture(session, %{})

      session = %{session | user: user}

      conn =
        conn
        |> Plug.Test.init_test_session(account_id: session.account.id, user_id: session.user.id)

      {:ok, %{conn: conn, session: session}}
    end

    test "disconnected and connected render", %{conn: conn, session: session} do
      path = Routes.tour_path(conn, :index)
      {:ok, tour_live, html} = live(conn, path)

      assert html =~ "Welcome #{session.account.name}!"
      assert render(tour_live) =~ "Welcome #{session.account.name}!"
    end
  end
end
