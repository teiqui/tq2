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

    test "with default options" do
      link =
        "test"
        |> icon_link(to: "#test")
        |> safe_to_string

      assert link =~ "bi-test"
      assert link =~ "href=\"#test\""
    end

    test "to clipboard" do
      link =
        [icon: "files", text: "123-text"]
        |> link_to_clipboard()
        |> safe_to_string

      assert link =~ "bi-files"
      assert link =~ "data-text=\"123-text\""
    end
  end
end
