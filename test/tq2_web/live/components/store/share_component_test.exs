defmodule Tq2Web.Store.ShareComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2Web.Store.ShareComponent

  @token "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c="

  describe "render" do
    test "render share with empty cart" do
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
end
