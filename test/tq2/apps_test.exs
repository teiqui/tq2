defmodule Tq2.AppsTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [app_mercado_pago_fixture: 0, create_session: 1]
  import Tq2.Support.MercadoPagoHelper, only: [mock_check_credentials: 1]

  alias Tq2.Apps
  alias Tq2.Apps.MercadoPago

  @mp_valid_attrs %{
    "name" => "mercado_pago",
    "data" => %{"access_token" => "TEST-123-asd-123"},
    "status" => "active"
  }
  @mp_invalid_attrs %{
    "name" => "mercado_pago",
    "data" => %{"access_token" => nil},
    "status" => "unknown"
  }

  describe "apps" do
    setup [:create_session]

    test "list_apps/2 returns all apps", %{session: %{account: account}} do
      %{app: app} = app_mercado_pago_fixture()

      assert Enum.map(Apps.list_apps(account), & &1.id) == [app.id]
    end
  end

  describe "mercado pago app" do
    setup [:create_session]

    test "create_app/2 with valid data creates a mercado_pago app", %{session: session} do
      mock_check_credentials do
        assert {:ok, %MercadoPago{} = app} = Apps.create_app(session, @mp_valid_attrs)
        assert app.name == "mercado_pago"
        assert app.status == @mp_valid_attrs["status"]
        assert app.data.access_token == @mp_valid_attrs["data"]["access_token"]
      end
    end

    test "create_app/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = Apps.create_app(session, @mp_invalid_attrs)
    end

    test "get_app/1 returns MercadoPagoApp", %{session: %{account: account}} do
      %{app: app} = app_mercado_pago_fixture()

      assert app == Apps.get_app(account, "mercado_pago")
    end

    test "update_app/3 with valid data updates the app", %{session: session} do
      %{app: app} = app_mercado_pago_fixture()

      update_attrs = %{status: "paused", data: Map.from_struct(app.data)}

      assert {:ok, %MercadoPago{} = app} = Apps.update_app(session, app, update_attrs)
      assert app.status == update_attrs.status
      assert app.data.access_token
      assert app.data.user_id
    end

    test "update_app/3 with invalid data returns error changeset", %{session: session} do
      %{app: app} = app_mercado_pago_fixture()

      assert {:error, %Ecto.Changeset{}} = Apps.update_app(session, app, @mp_invalid_attrs)

      assert app == Apps.get_app(session.account, "mercado_pago")
    end

    test "delete_app/2 deletes the app", %{session: session} do
      %{app: app} = app_mercado_pago_fixture()

      assert {:ok, %MercadoPago{}} = Apps.delete_app(session, app)
      refute Apps.get_app(session.account, "mercado_pago")
    end

    test "change_app/2 returns a MercadoPago changeset", %{session: %{account: account}} do
      %{app: app} = app_mercado_pago_fixture()

      assert %Ecto.Changeset{} = Apps.change_app(account, app)
    end
  end
end
