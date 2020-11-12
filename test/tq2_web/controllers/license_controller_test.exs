defmodule Tq2Web.LicenseControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  def license_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    license = Tq2.Accounts.get_license!(account)

    %{license: license}
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      response = get(conn, Routes.license_path(conn, :show))

      assert html_response(response, 302)
      assert response.halted
    end
  end

  describe "show" do
    setup [:license_fixture]

    @tag login_as: "test@user.com"
    test "show license", %{conn: conn, license: license} do
      conn = get(conn, Routes.license_path(conn, :show))
      response = html_response(conn, 200)

      assert response =~ String.capitalize(license.status)
    end
  end
end
