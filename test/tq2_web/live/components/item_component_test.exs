defmodule Tq2Web.ItemComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2.Inventories.{Category, Item}
  alias Tq2.Transactions.Cart
  alias Tq2Web.ItemComponent

  describe "render" do
    test "render item with image and no price selected" do
      item = item()
      cart = cart()
      store = store()
      content = render_component(ItemComponent, store: store, cart: cart, item: item, id: item.id)

      assert content =~ item.name
      assert content =~ "<img"
      refute content =~ "<svg"
      refute content =~ "<del"
    end

    test "render item with no image and no price selected" do
      item = %{item() | image: nil}
      cart = cart()
      store = store()
      content = render_component(ItemComponent, store: store, cart: cart, item: item, id: item.id)

      assert content =~ item.name
      assert content =~ "<svg"
      refute content =~ "<del"
    end

    test "render item with image and promotional price selected" do
      item = item()
      cart = %{cart() | lines: [%Tq2.Transactions.Line{}]}
      store = store()
      price = Money.to_string(item.price, symbol: true)
      promotional_price = Money.to_string(item.promotional_price, symbol: true)
      content = render_component(ItemComponent, store: store, cart: cart, item: item, id: item.id)

      assert content =~ item.name
      assert content =~ "<img"
      assert content =~ "#{price}</del>"
      refute content =~ "<svg"
      refute content =~ "#{promotional_price}</del>"
    end

    test "render item with image and regular price selected" do
      item = item()
      cart = %{cart() | price_type: "regular", lines: [%Tq2.Transactions.Line{}]}
      store = store()
      price = Money.to_string(item.price, symbol: true)
      promotional_price = Money.to_string(item.promotional_price, symbol: true)
      content = render_component(ItemComponent, store: store, cart: cart, item: item, id: item.id)

      assert content =~ item.name
      assert content =~ "<img"
      assert content =~ "#{promotional_price}</del>"
      refute content =~ "<svg"
      refute content =~ "#{price}</del>"
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

  defp store do
    %Tq2.Shops.Store{
      name: "some name",
      description: "some description",
      slug: "some_slug",
      published: true,
      logo: %Plug.Upload{
        content_type: "image/png",
        filename: "test.png",
        path: Path.absname("test/support/fixtures/files/test.png")
      },
      configuration: %Tq2.Shops.Configuration{
        require_email: true,
        require_phone: true,
        pickup: true,
        pickup_time_limit: "some time limit",
        delivery: true,
        delivery_area: "some delivery area",
        delivery_time_limit: "some time limit",
        pay_on_delivery: true
      },
      data: %Tq2.Shops.Data{
        address: "some address",
        phone: "some phone",
        email: "some@email.com",
        whatsapp: "some whatsapp",
        facebook: "some facebook",
        instagram: "some instagram"
      },
      location: %Tq2.Shops.Location{
        latitude: "12",
        longitude: "123"
      }
    }
  end

  defp cart do
    %Cart{
      price_type: "promotional",
      account_id: "1",
      lines: []
    }
  end
end
