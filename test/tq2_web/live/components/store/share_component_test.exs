defmodule Tq2Web.Store.ShareComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Utils.Urls, only: [store_uri: 0]

  alias Tq2Web.Store.ShareComponent

  @token "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c="

  describe "render" do
    test "render store share" do
      store = store()

      content =
        render_component(ShareComponent,
          id: :test,
          class: "test",
          store: store,
          token: @token,
          align_right: false,
          inner_block: fn _, _ -> "Test content" end
        )

      assert content =~ store.name
      assert content =~ "Test content"
      assert content =~ Routes.counter_url(store_uri(), :index, store, referral: @token)
    end

    test "render item share" do
      store = store()
      item = item()

      content =
        render_component(ShareComponent,
          id: :test,
          class: "test",
          store: store,
          item: item,
          token: @token,
          align_right: false,
          inner_block: fn _, _ -> "Test content" end
        )

      assert content =~ "Test content"
      assert content =~ Routes.item_url(store_uri(), :index, store, item, referral: @token)
      refute content =~ Routes.counter_url(store_uri(), :index, store, referral: @token)
    end
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
        address: "some address",
        delivery: true,
        delivery_area: "some delivery area",
        delivery_time_limit: "some time limit",
        pay_on_delivery: true
      },
      data: %Tq2.Shops.Data{
        phone: "555-5555",
        email: "some@email.com",
        whatsapp: "+549555-5555",
        facebook: "some facebook",
        instagram: "some instagram"
      },
      location: %Tq2.Shops.Location{
        latitude: "12",
        longitude: "123"
      }
    }
  end

  defp item do
    %Tq2.Inventories.Item{
      id: "1",
      name: "Chocolate",
      description: "Very good",
      visibility: "visible",
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      image: "test.png",
      account_id: "1",
      category_id: "1",
      category: %Tq2.Inventories.Category{
        id: "1",
        name: "Candy",
        ordinal: "0"
      }
    }
  end
end
