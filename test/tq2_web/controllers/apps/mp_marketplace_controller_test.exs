defmodule Tq2Web.Apps.MpMarketplaceControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  import Mock

  import Tq2.Fixtures, only: [default_account: 0]

  alias Tq2.Apps
  alias Tq2.Apps.MercadoPago, as: MPApp

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :show, "123"))

      assert html_response(conn, 302)
      assert conn.halted
    end
  end

  describe "mercado pago with app" do
    @tag login_as: "test@user.com"
    test "redirects to index with error", %{conn: conn} do
      mercado_pago_fixture()

      conn = get(conn, Routes.mp_marketplace_path(conn, :show))

      assert html_response(conn, 302)
      assert redirected_to(conn) == Routes.app_path(conn, :index)
      assert get_flash(conn, :error) =~ "Already authorized"
    end
  end

  describe "mercado pago" do
    @tag login_as: "test@user.com"
    test "create app with valid response", %{conn: conn} do
      marketplace = %{
        "access_token" => "MARKETPLACE_SELLER_TOKEN",
        "user_id" => "123",
        "expires_in" => 15_552_000
      }

      with_mock HTTPoison, mock_post_with(marketplace) do
        conn = get(conn, Routes.mp_marketplace_path(conn, :show, code: 123))

        assert html_response(conn, 302)
        assert redirected_to(conn) == Routes.app_path(conn, :index)
        assert get_flash(conn, :info) =~ "Successfully authorized"

        app = default_account() |> Apps.get_app("mercado_pago")

        assert app.status == "active"
        assert app.data["access_token"] == "MARKETPLACE_SELLER_TOKEN"
      end
    end

    @tag login_as: "test@user.com"
    test "redirected_to new with invalid response", %{conn: conn} do
      with_mock HTTPoison, mock_post_with(%{}) do
        conn = get(conn, Routes.mp_marketplace_path(conn, :show, code: 123))

        assert html_response(conn, 302)
        assert redirected_to(conn) == Routes.app_path(conn, :new, name: "mercado_pago")
        assert get_flash(conn, :error) == {:safe, "Invalid MercadoPago token"}
      end
    end

    @tag login_as: "test@user.com"
    test "redirect to new with error", %{conn: conn} do
      conn = get(conn, Routes.mp_marketplace_path(conn, :show))

      assert html_response(conn, 302)
      assert redirected_to(conn) == Routes.app_path(conn, :new, name: "mercado_pago")
      assert get_flash(conn, :error) == "Invalid authorization"
    end
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

  defp mock_post_with(%{} = body, code \\ 201) do
    json_body = body |> Jason.encode!()

    [
      post: fn _url, _params, _headers ->
        {:ok, %HTTPoison.Response{status_code: code, body: json_body}}
      end
    ]
  end
end
