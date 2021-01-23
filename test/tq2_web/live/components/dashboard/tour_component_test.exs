defmodule Tq2Web.Dashboard.TourComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2Web.Dashboard.TourComponent

  describe "render" do
    test "render tour" do
      content = render_component(TourComponent, [])

      assert content =~ "On the main dashboard"
    end
  end
end
