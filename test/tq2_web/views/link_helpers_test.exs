defmodule Tq2Web.LinkHelpersTest do
  use Tq2Web.ConnCase, async: true

  describe "link" do
    import Tq2Web.LinkHelpers
    import Phoenix.HTML, only: [safe_to_string: 1]

    test "with default options" do
      link =
        icon_link("test", to: "#test")
        |> safe_to_string

      assert link =~ "bootstrap-icons.svg#test"
      assert link =~ "href=\"#test\""
    end
  end
end
