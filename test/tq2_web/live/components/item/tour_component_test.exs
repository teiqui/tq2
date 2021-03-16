defmodule Tq2Web.Item.TourComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2Web.Item.TourComponent

  describe "render" do
    test "render tour" do
      content = render_component(TourComponent, [])

      assert content =~ "Complete with info about the item"
    end
  end
end
