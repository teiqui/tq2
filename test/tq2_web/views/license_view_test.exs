defmodule Tq2Web.LicenseViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.LicenseView

  import Phoenix.View
  import Ecto.Query

  test "renders show.html", %{conn: conn} do
    license = license()

    content = render_to_string(LicenseView, "show.html", conn: conn, license: license)

    assert String.contains?(content, String.capitalize(license.status))
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

  defp license do
    account =
      Tq2.Accounts.Account
      |> where(name: "test_account")
      |> join(:left, [a], l in assoc(a, :license))
      |> preload([a, l], license: l)
      |> Tq2.Repo.one()

    account.license
  end
end
