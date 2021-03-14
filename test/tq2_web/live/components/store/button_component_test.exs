defmodule Tq2Web.Store.ButtonComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2.Transactions.{Cart, Line}
  alias Tq2Web.Store.ButtonComponent

  @token "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c="

  describe "render" do
    test "render button with empty cart" do
      cart = cart()
      store = store()

      content =
        render_component(ButtonComponent,
          cart: cart,
          store: store,
          token: @token,
          to: "#",
          enabled: true,
          inner_block: fn _, _ -> "Test content" end
        )

      assert content == ""
    end

    test "render button with lines in cart" do
      lines = [
        %Line{
          name: "some name",
          quantity: 1,
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS)
        },
        %Line{
          name: "some name",
          quantity: 2,
          price: Money.new(120, :ARS),
          promotional_price: Money.new(110, :ARS)
        }
      ]

      cart = %{cart() | lines: lines}
      store = store()

      content =
        render_component(ButtonComponent,
          cart: cart,
          store: store,
          token: @token,
          to: "/test_path",
          enabled: true,
          inner_block: fn _, _ -> "Test content" end
        )

      assert content =~ "Test content"
      assert content =~ "/test_path"
      refute content =~ "disabled"
    end

    test "render disabled button with lines in cart and regular price" do
      lines = [
        %Line{
          name: "some name",
          quantity: 1,
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS)
        }
      ]

      cart = %{cart() | lines: lines, price_type: "regular"}
      store = store()

      content =
        render_component(ButtonComponent,
          cart: cart,
          store: store,
          token: @token,
          to: "/test_path",
          enabled: false,
          inner_block: fn _, _ -> "Test content" end
        )

      assert content =~ "Test content"
      assert content =~ "/test_path"
      assert content =~ "disabled"
    end
  end

  defp cart do
    %Cart{
      token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
      price_type: "promotional",
      account_id: "1",
      lines: []
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
