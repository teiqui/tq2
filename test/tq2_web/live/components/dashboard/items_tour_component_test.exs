defmodule Tq2Web.Dashboard.ItemsTourComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2Web.Dashboard.ItemsTourComponent

  describe "render" do
    test "render tour" do
      content = render_component(ItemsTourComponent, [])

      assert content =~ "Inside More you&#39;ll find"
    end
  end
end
