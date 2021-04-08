defmodule Tq2Web.Import.PredefinedComponentTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [init_test_session: 1]

  describe "render" do
    setup [:init_test_session]

    if System.get_env("CREDENTIALS_PATH") == nil, do: @tag(:skip)

    test "import event triggers :import", %{conn: conn} do
      path = Routes.import_path(conn, :show, "predefined")
      {:ok, import_live, html} = live(conn, path)

      assert html =~ "Quesos y Fiambres"
      assert html =~ "Import"

      :erlang.trace(import_live.pid, true, [:receive])

      pid = import_live.pid

      import_live
      |> form("form", import: %{grid_title: "Quesos y Fiambres"})
      |> render_submit()

      assert_receive {:trace, ^pid, :receive, {:import, _opts}}, 1_000
    end
  end
end
