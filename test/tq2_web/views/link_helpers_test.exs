defmodule Tq2Web.LinkHelpersTest do
  use Tq2Web.ConnCase, async: true

  describe "link" do
    import Tq2Web.LinkHelpers
    import Phoenix.HTML, only: [safe_to_string: 1]

    setup %{conn: conn} do
      conn =
        conn
        |> bypass_through(Tq2Web.Router, :browser)
        |> get("/")

      {:ok, %{conn: conn}}
    end

    test "with default options", %{conn: conn} do
      link =
        conn
        |> icon_link("test", to: "#test")
        |> safe_to_string

      assert link =~ "bootstrap-icons.svg#test"
      assert link =~ "href=\"#test\""
    end
  end
end
