defmodule Tq2Web.Store.TeamComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2Web.Store.TeamComponent

  describe "render" do
    test "render team with no referral" do
      store = store()
      content = render_component(TeamComponent, id: :team, store: store, referral_customer: nil)

      assert content =~ "Share the store"
      refute content =~ "disabled"
      refute content =~ "avatar_join"
    end

    test "render team with referral" do
      customer = customer()
      store = store()

      content =
        render_component(TeamComponent, id: :team, store: store, referral_customer: customer)

      assert content =~ "Great!"
      assert content =~ customer.name
      assert content =~ "disabled"
      assert content =~ "avatar_join"
    end
  end

  defp customer do
    %Tq2.Sales.Customer{
      name: "some name",
      email: "some@email.com",
      phone: "555-5555",
      address: "some address"
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
