defmodule Tq2Web.AppControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  import Mock

  import Tq2.Fixtures,
    only: [
      app_mercado_pago_fixture: 1,
      conekta_app: 0,
      default_account: 0,
      transbank_app: 0
    ]

  import Tq2.Support.MercadoPagoHelper, only: [mock_check_credentials: 1]

  alias Tq2.Apps.WireTransfer, as: WTApp

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

      assert response =~ "Create"
    end

    @tag login_as: "test@user.com"
    test "redirect to index after create", %{conn: conn} do
      mock_check_credentials do
        conn =
          post conn, Routes.app_path(conn, :create),
            mercado_pago: %{status: "active", data: %{access_token: "TEST-123-asd-123"}}

        assert html_response(conn, 302)
        assert redirected_to(conn) == Routes.app_path(conn, :index)
        assert get_flash(conn, :info) =~ "App created successfully"
      end
    end
  end

  describe "mercado pago with app" do
    setup [:app_mercado_pago_fixture]

    @tag login_as: "test@user.com"
    test "lists with apps", %{conn: conn, app: _app} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "MercadoPago"
      assert response =~ "Edit"
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

      assert response =~ "is invalid"
      assert response =~ "can&#39;t be blank"
    end

    @tag login_as: "test@user.com"
    test "deletes chosen app", %{conn: conn, app: app} do
      conn = delete(conn, Routes.app_path(conn, :delete, app))

      assert redirected_to(conn) == Routes.app_path(conn, :index)
    end
  end

  describe "wire transfer without app" do
    @tag login_as: "test@user.com"
    test "lists without apps", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "Wire transfer"
      assert response =~ "Install"
    end

    @tag login_as: "test@user.com"
    test "render new", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :new, %{"name" => "wire_transfer"}))
      response = html_response(conn, 200)

      assert response =~ "Create"
    end

    @tag login_as: "test@user.com"
    test "redirect to index after create", %{conn: conn} do
      conn =
        post conn, Routes.app_path(conn, :create),
          wire_transfer: %{
            status: "active",
            data: %{description: "Pay me", account_number: "123"}
          }

      assert html_response(conn, 302)
      assert redirected_to(conn) == Routes.app_path(conn, :index)
      assert get_flash(conn, :info) =~ "App created successfully"
    end
  end

  describe "wire transfer with app" do
    setup [:wire_transfer_fixture]

    @tag login_as: "test@user.com"
    test "lists with apps", %{conn: conn, app: _app} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "Wire transfer"
      assert response =~ "Edit"
    end

    @tag login_as: "test@user.com"
    test "render edit", %{conn: conn, app: app} do
      conn = get(conn, Routes.app_path(conn, :edit, app))
      response = html_response(conn, 200)

      assert response =~ app.status
    end

    @tag login_as: "test@user.com"
    test "redirect to index after update", %{conn: conn, app: app} do
      conn = put conn, Routes.app_path(conn, :update, app), wire_transfer: %{status: "paused"}

      assert html_response(conn, 302)
      assert redirected_to(conn) == Routes.app_path(conn, :index)
      assert get_flash(conn, :info) =~ "updated successfully"
    end

    @tag login_as: "test@user.com"
    test "redirect to edit after invalid update", %{conn: conn, app: app} do
      conn =
        put conn, Routes.app_path(conn, :update, app),
          wire_transfer: %{
            status: "unknown",
            data: %{account_number: nil, description: nil}
          }

      response = html_response(conn, 200)

      assert response =~ "is invalid"
    end

    @tag login_as: "test@user.com"
    test "deletes chosen app", %{conn: conn, app: app} do
      conn = delete(conn, Routes.app_path(conn, :delete, app))

      assert redirected_to(conn) == Routes.app_path(conn, :index)
    end
  end

  describe "transbank without app" do
    setup [:default_account_to_chile]

    @tag login_as: "test@user.com"
    test "lists without apps", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "Transbank - Onepay"
      assert response =~ "Install"
    end

    @tag login_as: "test@user.com"
    test "render new", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :new, %{"name" => "transbank"}))
      response = html_response(conn, 200)

      assert response =~ "Create"
    end

    @tag login_as: "test@user.com"
    test "redirect to index after create", %{conn: conn} do
      mock = [check_credentials: fn _, _ -> :ok end]

      with_mock Tq2.Gateways.Transbank, mock do
        conn =
          post conn, Routes.app_path(conn, :create),
            transbank: %{
              status: "active",
              data: %{api_key: "123-asd", shared_secret: "asd"}
            }

        assert html_response(conn, 302)
        assert redirected_to(conn) == Routes.app_path(conn, :index)
        assert get_flash(conn, :info) =~ "App created successfully"
      end
    end
  end

  describe "transbank with app" do
    setup [:transbank_fixture, :default_account_to_chile]

    @tag login_as: "test@user.com"
    test "lists with apps", %{conn: conn, app: _app} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "Transbank - Onepay"
      assert response =~ "Edit"
    end

    @tag login_as: "test@user.com"
    test "render edit", %{conn: conn, app: app} do
      conn = get(conn, Routes.app_path(conn, :edit, app))
      response = html_response(conn, 200)

      assert response =~ app.status
    end

    @tag login_as: "test@user.com"
    test "redirect to index after update", %{conn: conn, app: app} do
      conn = put conn, Routes.app_path(conn, :update, app), transbank: %{status: "paused"}

      assert html_response(conn, 302)
      assert redirected_to(conn) == Routes.app_path(conn, :index)
      assert get_flash(conn, :info) =~ "updated successfully"
    end

    @tag login_as: "test@user.com"
    test "redirect to edit after invalid update", %{conn: conn, app: app} do
      conn =
        put conn, Routes.app_path(conn, :update, app),
          transbank: %{
            status: "unknown",
            data: %{account_number: nil, description: nil}
          }

      response = html_response(conn, 200)

      assert response =~ "is invalid"
    end

    @tag login_as: "test@user.com"
    test "deletes chosen app", %{conn: conn, app: app} do
      conn = delete(conn, Routes.app_path(conn, :delete, app))

      assert redirected_to(conn) == Routes.app_path(conn, :index)
    end
  end

  describe "conekta without app" do
    setup [:default_account_to_mexico]

    @tag login_as: "test@user.com"
    test "lists without apps", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "Conekta"
      assert response =~ "Install"
    end

    @tag login_as: "test@user.com"
    test "render new", %{conn: conn} do
      conn = get(conn, Routes.app_path(conn, :new, %{"name" => "conekta"}))
      response = html_response(conn, 200)

      assert response =~ "Create"
    end

    @tag login_as: "test@user.com"
    test "redirect to index after create", %{conn: conn} do
      mock = [check_credentials: fn _ -> :ok end]

      with_mock Tq2.Gateways.Conekta, mock do
        conn =
          post conn, Routes.app_path(conn, :create),
            conekta: %{
              status: "active",
              data: %{api_key: "key_123"}
            }

        assert html_response(conn, 302)
        assert redirected_to(conn) == Routes.app_path(conn, :index)
        assert get_flash(conn, :info) =~ "App created successfully"
      end
    end
  end

  describe "conekta with app" do
    setup [:conekta_fixture, :default_account_to_mexico]

    @tag login_as: "test@user.com"
    test "lists with apps", %{conn: conn, app: _app} do
      conn = get(conn, Routes.app_path(conn, :index))
      response = html_response(conn, 200)

      assert response =~ "Apps"
      assert response =~ "Conekta"
      assert response =~ "Edit"
    end

    @tag login_as: "test@user.com"
    test "render edit", %{conn: conn, app: app} do
      conn = get(conn, Routes.app_path(conn, :edit, app))
      response = html_response(conn, 200)

      assert response =~ app.status
    end

    @tag login_as: "test@user.com"
    test "redirect to index after update", %{conn: conn, app: app} do
      conn = put conn, Routes.app_path(conn, :update, app), conekta: %{status: "paused"}

      assert html_response(conn, 302)
      assert redirected_to(conn) == Routes.app_path(conn, :index)
      assert get_flash(conn, :info) =~ "updated successfully"
    end

    @tag login_as: "test@user.com"
    test "redirect to edit after invalid update", %{conn: conn, app: app} do
      conn =
        put conn, Routes.app_path(conn, :update, app),
          conekta: %{
            status: "unknown",
            data: %{api_key: nil}
          }

      response = html_response(conn, 200)

      assert response =~ "is invalid"
    end

    @tag login_as: "test@user.com"
    test "deletes chosen app", %{conn: conn, app: app} do
      conn = delete(conn, Routes.app_path(conn, :delete, app))

      assert redirected_to(conn) == Routes.app_path(conn, :index)
    end
  end

  defp wire_transfer_fixture(_) do
    attrs = %{
      status: "active",
      data: %{"description" => "Pay me", "account_number" => "123-123"}
    }

    {:ok, app} =
      default_account()
      |> WTApp.changeset(%WTApp{}, attrs)
      |> Tq2.Repo.insert()

    %{app: app}
  end

  defp transbank_fixture(_) do
    %{app: transbank_app()}
  end

  defp conekta_fixture(_) do
    %{app: conekta_app()}
  end

  defp default_account_to_chile(%{conn: conn}), do: default_account_to_country(conn, "cl")

  defp default_account_to_mexico(%{conn: conn}), do: default_account_to_country(conn, "mx")

  defp default_account_to_country(conn, country) do
    {:ok, account} = default_account() |> Tq2.Accounts.update_account(%{country: country})

    session = %{conn.assigns.current_session | account: account}

    conn = conn |> assign(:current_session, session)

    %{conn: conn}
  end
end
