defmodule Tq2Web.AppViewTest do
  use Tq2Web.ConnCase, async: true
  use Tq2.Support.LoginHelper

  import Phoenix.HTML, only: [safe_to_string: 1]
  import Tq2.Fixtures, only: [default_account: 0]

  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2Web.AppView

  test "link to edit", %{conn: conn} do
    app = mercado_pago_fixture()

    content =
      conn
      |> AppView.link_to_edit(app)
      |> safe_to_string()

    assert content =~ app.name
    assert content =~ "href"
    assert content =~ "svg#pencil"
  end

  test "link to delete", %{conn: conn} do
    app = mercado_pago_fixture()

    content =
      conn
      |> AppView.link_to_delete(app)
      |> safe_to_string()

    assert content =~ app.name
    assert content =~ "href"
    assert content =~ "delete"
  end

  test "statuses collection" do
    collection = AppView.statuses_collection()

    assert Enum.count(collection) == 2
    assert Map.values(collection) == ~w(active paused)
  end

  test "app status" do
    content =
      mercado_pago_fixture()
      |> AppView.app_status()
      |> safe_to_string()

    assert content =~ "Active"
    assert content =~ "badge-success"
  end

  test "app kinds for cards" do
    assert ~w(mercado_pago) == AppView.app_names()
  end

  test "app from apps by name" do
    apps = [%MPApp{}]

    assert %MPApp{} = AppView.app_by_name(apps, "mercado_pago")
    assert %MPApp{} = AppView.app_by_name([], "mercado_pago")
    refute AppView.app_by_name(apps, "unknown")
  end

  test "build app" do
    app = AppView.build_app("mercado_pago")

    assert %MPApp{} = app
  end

  test "mp link to authorize" do
    content =
      default_account()
      |> AppView.mp_link_to_authorize()
      |> safe_to_string()

    assert content =~ "<a"
    assert content =~ "Link account"
    assert content =~ "auth.mercadopago.com.ar"
  end

  test "mp link to commissions" do
    content =
      default_account()
      |> AppView.mp_link_to_commissions()
      |> safe_to_string()

    assert content =~ "<a"
    assert content =~ "Commissions"
    assert content =~ "svg#percent"
  end

  test "mp link to install", %{conn: conn} do
    content =
      conn
      |> AppView.mp_link_to_install()
      |> safe_to_string()

    assert content =~ "Install"
    assert content =~ "/apps/new?name=mercado_pago"
  end

  defp mercado_pago_fixture() do
    attrs = %{
      status: "active",
      data: %{"access_token" => 123}
    }

    {:ok, app} =
      default_account()
      |> MPApp.changeset(%MPApp{}, attrs)
      |> Tq2.Repo.insert()

    app
  end
end
