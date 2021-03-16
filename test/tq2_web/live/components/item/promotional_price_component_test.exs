defmodule Tq2Web.Item.PromotionalPriceComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2Web.Item.PromotionalPriceComponent

  describe "render" do
    test "render tour" do
      content = render_component(PromotionalPriceComponent, [])

      assert content =~ "Teiqui price must be lower than regular"
    end
  end
end
