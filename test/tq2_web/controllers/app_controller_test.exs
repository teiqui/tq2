defmodule Tq2Web.AppControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  import Tq2.Fixtures, only: [default_account: 0]

  alias Tq2.Apps.MercadoPago, as: MPApp

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.app_path(conn, :index)),
          get(conn, Routes.app_path(conn, :new)),
          post(conn, Routes.app_path(conn, :create, %{})),
          get(conn, Routes.app_path(conn, :show, "123")),
          get(conn, Routes.app_path(conn, :edit, "123")),
          put(conn, Routes.app_path(conn, :update, "123", %{})),
          delete(conn, Routes.app_path(conn, :delete, "123"))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "mercado pago without app" do
    @tag login_as: "test@user.com"
    test "lists without apps", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "MercadoPago"
      assert response =~ "Install"
    end

    @tag login_as: "test@user.com"
    test "render new", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :new, %{"name" => "mercado_pago"}))
      response = html_response(conn, 200)

      assert response =~ "Link account"
    end
  end

  describe "mercado pago with app" do
    setup [:mercado_pago_fixture]

    @tag login_as: "test@user.com"
    test "lists with apps", %{conn: conn, app: _app} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "MercadoPago"
      assert response =~ "Edit"
      refute response =~ "Install"
    end

    @tag login_as: "test@user.com"
    test "render edit", %{conn: conn, app: app} do
      conn = get(conn, Routes.app_path(conn, :edit, app))
      response = html_response(conn, 200)

      assert response =~ app.status
    end

    @tag login_as: "test@user.com"
    test "redirect to index after update", %{conn: conn, app: app} do
      conn = put conn, Routes.app_path(conn, :update, app), mercado_pago: %{status: "paused"}

      assert html_response(conn, 302)
      assert redirected_to(conn) == Routes.app_path(conn, :index)
      assert get_flash(conn, :info) =~ "updated successfully"
    end

    @tag login_as: "test@user.com"
    test "redirect to edit after invalid update", %{conn: conn, app: app} do
      conn =
        put conn, Routes.app_path(conn, :update, app),
          mercado_pago: %{status: "unknown", data: %{access_token: nil}}

      response = html_response(conn, 200)

      assert response =~ "Invalid MercadoPago token"
      assert response =~ "is invalid"
    end

    @tag login_as: "test@user.com"
    test "deletes chosen app", %{conn: conn, app: app} do
      conn = delete(conn, Routes.app_path(conn, :delete, app))

      assert redirected_to(conn) == Routes.app_path(conn, :index)
    end
  end

  defp mercado_pago_fixture(_) do
    attrs = %{
      status: "active",
      data: %{"access_token" => 123}
    }

    {:ok, app} =
      default_account()
      |> MPApp.changeset(%MPApp{}, attrs)
      |> Tq2.Repo.insert()

    %{app: app}
  end
end
