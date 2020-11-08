defmodule Tq2Web.LayoutViewTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]

  alias Tq2Web.LayoutView

  test "locale" do
    assert LayoutView.locale() == "en"
  end

  describe "menu item" do
    test "should return active when root path matches", %{conn: conn} do
      result =
        %{conn | request_path: "/test/1"}
        |> LayoutView.menu_item([to: "/test"], do: "test")
        |> safe_to_string

      assert result =~ "active"
    end

    test "should not return active when root path mismatches", %{conn: conn} do
      result =
        %{conn | request_path: "/other/1"}
        |> LayoutView.menu_item([to: "/test"], do: "test")
        |> safe_to_string

      refute result =~ "active"
    end
  end
end
