defmodule Tq2Web.StoreViewTest do
  use Tq2Web.ConnCase, async: true
  use Tq2.Support.LoginHelper

  alias Tq2Web.StoreView
  alias Tq2.Shops
  alias Tq2.Shops.Store

  import Phoenix.View

  @tag login_as: "test@user.com"
  test "renders new.html", %{conn: conn} do
    changeset = account() |> Shops.change_store(%Store{})

    content =
      render_to_string(StoreView, "new.html",
        conn: conn,
        changeset: changeset,
        current_session: conn.assigns.current_session
      )

    assert String.contains?(content, "New store")
  end

  @tag login_as: "test@user.com"
  test "renders edit.html", %{conn: conn} do
    store = store()
    changeset = account() |> Shops.change_store(store)

    content =
      render_to_string(StoreView, "edit.html",
        conn: conn,
        store: store,
        changeset: changeset,
        current_session: conn.assigns.current_session
      )

    assert String.contains?(content, store.name)
  end

  defp account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end

  defp store do
    %Store{
      id: "1",
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
