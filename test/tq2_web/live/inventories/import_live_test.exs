defmodule Tq2Web.Inventories.ImportLiveTest do
  use Tq2Web.ConnCase

  import Tq2.Fixtures, only: [create_session: 0, user_fixture: 2]
  import Phoenix.LiveViewTest

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          live(conn, Routes.import_path(conn, :index))
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

      {:ok, %{conn: conn}}
    end

    if System.get_env("CREDENTIALS_PATH") == nil, do: @tag(:skip)

    test "disconnected and connected render", %{conn: conn} do
      path = Routes.import_path(conn, :index)
      {:ok, import_live, html} = live(conn, path)

      assert html =~ "Import"
      assert render(import_live) =~ "Import"
    end

    if System.get_env("CREDENTIALS_PATH") == nil, do: @tag(:skip)

    test "import event", %{conn: conn} do
      path = Routes.import_path(conn, :index)
      {:ok, import_live, _html} = live(conn, path)

      :erlang.trace(import_live.pid, true, [:receive])

      pid = import_live.pid

      assert import_live
             |> element("form")
             |> render_submit(%{
               item: %{
                 "title" => "Quesos y Fiambres"
               }
             }) =~ "class=\"progress-bar\""

      assert_receive {:trace, ^pid, :receive, {:batch_import_finished, _result}}, 20_000
      assert render(import_live) =~ "13 items imported!"
    end
  end
end
