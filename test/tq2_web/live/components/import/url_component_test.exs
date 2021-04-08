defmodule Tq2Web.Import.UrlComponentTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [init_test_session: 1]

  describe "render" do
    setup [:init_test_session]

    test "import event triggers :read_titles", %{conn: conn} do
      path = Routes.import_path(conn, :show, "url")
      {:ok, import_live, _html} = live(conn, path)

      :erlang.trace(import_live.pid, true, [:receive])

      pid = import_live.pid
      sheet_id = :tq2 |> Application.get_env(:default_sheet_id)
      url = "docs.google.com/spreadsheets/d/#{sheet_id}"

      content =
        import_live
        |> form("form", read: %{url: url})
        |> render_submit()

      assert content =~ "Reading..."
      refute content =~ "Can't read spreadsheet"

      assert_receive {:trace, ^pid, :receive, {:read_titles, _sheet_id}}, 100

      assert import_live |> has_element?("button[type=\"submit\"]", "Import")
    end
  end
end
