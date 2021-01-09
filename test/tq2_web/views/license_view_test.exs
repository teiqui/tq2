defmodule Tq2Web.LicenseViewTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.View
  import Tq2.Fixtures, only: [default_account: 0]

  alias Tq2Web.LicenseView

  test "renders show.html", %{conn: conn} do
    license = license()

    content = render_to_string(LicenseView, "show.html", conn: conn, license: license)

    assert String.contains?(content, String.capitalize(license.status))
    refute String.contains?(content, "<table>")
  end

  test "status", %{conn: _} do
    license = license()
    content = license |> LicenseView.status()

    assert content == String.capitalize(license.status)
  end

  test "localize" do
    license = license()
    content = license.paid_until |> LicenseView.localize()

    {:ok, localized_paid_until} = Timex.format(license.paid_until, "{M}/{D}/{YYYY}")

    assert content == localized_paid_until
  end

  defp license, do: default_account().license
end
