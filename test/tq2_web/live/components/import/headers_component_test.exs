defmodule Tq2Web.Import.HeadersComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [init_test_session: 1]

  describe "render" do
    setup [:init_test_session]
    if System.get_env("CREDENTIALS_PATH") == nil, do: @tag(:skip)

    test "import event triggers :import", %{conn: conn} do
      path = Routes.import_path(conn, :show, "url")
      {:ok, import_live, _html} = live(conn, path)

      sheet_id = :tq2 |> Application.get_env(:default_sheet_id)

      send(import_live.pid, {:read_titles, sheet_id})

      content = import_live |> render()

      assert content =~ "Import"
      assert content =~ "Name"
      assert content =~ "Price"
      assert content =~ "Promotional price"

      import_live
      |> form("form",
        import: %{
          name: "Nombre del artículo",
          price: "Precio regular",
          promotional_price: "Precio Teiqui"
        }
      )
      |> render_submit()

      assert render(import_live) =~ "Importing items"
    end

    if System.get_env("CREDENTIALS_PATH") == nil, do: @tag(:skip)

    test "required fields", %{conn: conn} do
      path = Routes.import_path(conn, :show, "url")
      {:ok, import_live, _html} = live(conn, path)

      sheet_id = :tq2 |> Application.get_env(:default_sheet_id)

      send(import_live.pid, {:read_titles, sheet_id})

      content = import_live |> render()

      assert content =~ "Import"
      assert content =~ "Name"

      import_live
      |> form("form", import: %{promotional_price: "Precio Teiqui"})
      |> render_submit()

      # Ensure import error
      assert import_live |> has_element?("button[type=\"submit\"]:not(disabled)", "Import")
    end
  end
end
