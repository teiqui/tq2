defmodule Tq2Web.Licenses.CheckControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  import Mock

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      response = get(conn, Routes.license_path(conn, :show))

      assert html_response(response, 302)
      assert response.halted
    end
  end

  describe "show" do
    @default_payment %{
      id: 123,
      external_reference: "123",
      transaction_amount: 12.0,
      date_approved: Timex.now(),
      status: "approved",
      currency_id: "ARS"
    }

    @tag login_as: "test@user.com"
    test "check license", %{conn: conn} do
      mocked_fn = %{results: [@default_payment]} |> mock_get_with()

      with_mock HTTPoison, mocked_fn do
        conn = get(conn, Routes.license_check_path(conn, :show))

        assert html_response(conn, 302)
        assert get_flash(conn, :info) == "License updated"
      end
    end

    @tag login_as: "test@user.com"
    test "check license without update", %{conn: conn} do
      mocked_fn = %{results: []} |> mock_get_with()

      with_mock HTTPoison, mocked_fn do
        conn = get(conn, Routes.license_check_path(conn, :show))

        assert html_response(conn, 302)
        assert get_flash(conn, :info) == "Nothing to update"
      end
    end

    defp mock_get_with(%{} = body, code \\ 200) do
      json_body = body |> Jason.encode!()

      [
        get: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: code, body: json_body}}
        end
      ]
    end
  end
end
