defmodule Tq2.AppsTest do
  use Tq2.DataCase

  alias Tq2.Apps
  alias Tq2.Apps.MercadoPago
  alias Tq2.Accounts.{Account, Session}

  @mp_valid_attrs %{
    name: "mercado_pago",
    data: %{"access_token" => "123-asd"},
    status: "active"
  }
  @mp_invalid_attrs %{
    name: "mercado_pago",
    data: %{"access_token" => nil},
    status: "unknown"
  }

  describe "apps" do
    setup [:create_session]

    test "list_apps/2 returns all apps", %{session: session} do
      app = fixture_mercado_pago(session)

      assert Enum.map(Apps.list_apps(session.account), & &1.id) == [app.id]
    end
  end

  describe "mercado pago app" do
    setup [:create_session]

    test "create_app/2 with valid data creates a mercado_pago app", %{session: session} do
      assert {:ok, %MercadoPago{} = app} = Apps.create_app(session, @mp_valid_attrs)
      assert app.name == "mercado_pago"
      assert app.data == @mp_valid_attrs.data
      assert app.status == @mp_valid_attrs.status
    end

    test "create_app/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = Apps.create_app(session, @mp_invalid_attrs)
    end

    test "get_app/1 returns MercadoPagoApp", %{session: session} do
      app = fixture_mercado_pago(session)

      assert app == Apps.get_app(session.account, "mercado_pago")
    end

    test "update_app/3 with valid data updates the app", %{session: session} do
      app = fixture_mercado_pago(session)

      update_attrs = %{status: "paused", data: %{random_key: "value"}}

      assert {:ok, %MercadoPago{} = app} = Apps.update_app(session, app, update_attrs)
      assert app.data == update_attrs.data
      assert app.status == update_attrs.status
    end

    test "update_app/3 with invalid data returns error changeset", %{session: session} do
      app = fixture_mercado_pago(session)

      assert {:error, %Ecto.Changeset{}} = Apps.update_app(session, app, @mp_invalid_attrs)

      assert app == Apps.get_app(session.account, "mercado_pago")
    end

    test "delete_app/2 deletes the app", %{session: session} do
      app = fixture_mercado_pago(session)

      assert {:ok, %MercadoPago{}} = Apps.delete_app(session, app)
      refute Apps.get_app(session.account, "mercado_pago")
    end

    test "change_app/2 returns a MercadoPago changeset", %{session: session} do
      app = fixture_mercado_pago(session)

      assert %Ecto.Changeset{} = Apps.change_app(session.account, app)
    end
  end

  defp default_account do
    Account
    |> where(name: "test_account")
    |> Tq2.Repo.one()
  end

  defp create_session(_) do
    {:ok, session: %Session{account: default_account()}}
  end

  defp fixture_mercado_pago(session, attrs \\ %{}) do
    app_attrs = Enum.into(attrs, @mp_valid_attrs)
    {:ok, app} = Apps.create_app(session, app_attrs)

    app
  end
end
