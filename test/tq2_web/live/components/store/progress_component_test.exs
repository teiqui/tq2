defmodule Tq2Web.Store.ProgressComponentTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Tq2Web.Store.ProgressComponent

  describe "render" do
    test "render handing step" do
      content = render_component(ProgressComponent, step: :handing)

      assert content =~ "Handing"
      assert content =~ "Step 1 of 4"
      assert content =~ "role=\"progressbar\" style=\"width: 25%;\""
    end

    test "render checkout step" do
      content = render_component(ProgressComponent, step: :checkout)

      assert content =~ "Cart"
      assert content =~ "Step 2 of 4"
      assert content =~ "role=\"progressbar\" style=\"width: 50%;\""
    end

    test "render customer step" do
      content = render_component(ProgressComponent, step: :customer)

      assert content =~ "My data"
      assert content =~ "Step 3 of 4"
      assert content =~ "role=\"progressbar\" style=\"width: 75%;\""
    end

    test "render payment step" do
      content = render_component(ProgressComponent, step: :payment)

      assert content =~ "Payment methods"
      assert content =~ "Step 4 of 4"
      assert content =~ "role=\"progressbar\" style=\"width: 100%;\""
    end
  end
end
