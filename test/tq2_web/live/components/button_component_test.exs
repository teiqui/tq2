defmodule Tq2Web.ButtonComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2.Transactions.{Cart, Line}
  alias Tq2Web.ButtonComponent

  describe "render" do
    test "render button with empty cart" do
      cart = cart()
      store = store()
      content = render_component(ButtonComponent, cart: cart, store: store)

      assert content == ""
    end

    test "render button with lines in cart" do
      lines = [
        %Line{
          name: "some name",
          quantity: 1,
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS)
        },
        %Line{
          name: "some name",
          quantity: 2,
          price: Money.new(120, :ARS),
          promotional_price: Money.new(110, :ARS),
          cost: Money.new(100, :ARS)
        }
      ]

      cart = %{cart() | lines: lines}
      store = store()
      content = render_component(ButtonComponent, cart: cart, store: store)

      assert content =~ Money.to_string(Money.new(310, :ARS), symbol: true)
    end
  end

  defp cart do
    %Cart{
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
end