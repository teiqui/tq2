defmodule Tq2Web.ItemComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2.Inventories.{Category, Item}
  alias Tq2Web.ItemComponent

  describe "render" do
    test "render item with image" do
      item = item()
      content = render_component(ItemComponent, item: item, id: item.id)

      assert content =~ item.name
      assert content =~ "<img"
      refute content =~ "<svg"
    end

    test "render item with no image" do
      item = %{item() | image: nil}
      content = render_component(ItemComponent, item: item, id: item.id)

      assert content =~ item.name
      assert content =~ "<svg"
      refute content =~ "<img"
    end
  end

  defp item do
    %Item{
      id: "1",
      sku: "123",
      name: "Chocolate",
      description: "Very good",
      visibility: "visible",
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      cost: Money.new(80, :ARS),
      image: "test.png",
      account_id: "1",
      category_id: "1",
      category: %Category{
        id: "1",
        name: "Candy",
        ordinal: "0"
      }
    }
  end
end
