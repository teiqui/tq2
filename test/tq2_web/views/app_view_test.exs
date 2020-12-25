defmodule Tq2Web.AppViewTest do
  use Tq2Web.ConnCase, async: true
  use Tq2.Support.LoginHelper

  import Phoenix.HTML, only: [safe_to_string: 1]
  import Tq2.Fixtures, only: [default_account: 0]

  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2.Apps.WireTransfer, as: WTApp
  alias Tq2Web.AppView

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "link to show", %{conn: conn} do
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
    assert ~w(mercado_pago wire_transfer) == AppView.app_names()
  end

  test "app from apps by name" do
    apps = [%MPApp{}, %WTApp{}]

    assert %MPApp{} = AppView.app_by_name(apps, "mercado_pago")
    assert %MPApp{} = AppView.app_by_name([], "mercado_pago")
    assert %WTApp{} = AppView.app_by_name(apps, "wire_transfer")
    assert %WTApp{} = AppView.app_by_name([], "wire_transfer")
    refute AppView.app_by_name(apps, "unknown")
  end

  test "build app" do
    assert %MPApp{} = AppView.build_app("mercado_pago")
    assert %WTApp{} = AppView.build_app("wire_transfer")
    refute AppView.build_app("unknwon")
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

  test "mp link to commissions", %{conn: conn} do
    content =
      conn
      |> AppView.mp_link_to_commissions(default_account())
      |> safe_to_string()

    assert content =~ "<a"
    assert content =~ "Commissions"
    assert content =~ "svg#percent"
  end

  test "mp link to install", %{conn: conn} do
    content =
      conn
      |> AppView.link_to_install("mercado_pago")
      |> safe_to_string()

    assert content =~ "Install"
    assert content =~ "/apps/new?name=mercado_pago"
  end

  test "wire transfer link to install", %{conn: conn} do
    content =
      conn
      |> AppView.link_to_install("wire_transfer")
      |> safe_to_string()

    assert content =~ "Install"
    assert content =~ "/apps/new?name=wire_transfer"
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
