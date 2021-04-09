defmodule Tq2Web.Inventory.ImportLiveTest do
  use Tq2Web.ConnCase, async: true

  import Tq2.Fixtures, only: [init_test_session: 1]
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

  describe "render section list" do
    setup [:init_test_session]

    test "disconnected and connected render", %{conn: conn} do
      path = Routes.import_path(conn, :index)
      {:ok, import_live, html} = live(conn, path)

      content = import_live |> render()

      assert html =~ "Import"
      assert html =~ "Predefined"
      assert html =~ "Google spreadsheet"
      assert html =~ "Upload spreadsheet"
      assert content =~ "Import"
      assert content =~ "Predefined"
      assert content =~ "Google spreadsheet"
      assert content =~ "Upload spreadsheet"
    end
  end
end
