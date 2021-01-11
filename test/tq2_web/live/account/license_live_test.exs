defmodule Tq2Web.Account.LicenseLiveTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [init_test_session: 1]

  describe "render" do
    setup [:init_test_session]

    test "render trial license", %{conn: conn, session: %{account: %{license: license}}} do
      path = Routes.license_path(conn, :index)
      {:ok, _license_live, html} = live(conn, path)

      assert html =~ "License"
      assert html =~ "Trial"
      assert html =~ Timex.format!(license.paid_until, "{M}/{D}/{YYYY}")
    end
  end
end
