defmodule Tq2Web.LayoutViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.LayoutView

  test "locale" do
    assert LayoutView.locale() == "en"
  end
end
