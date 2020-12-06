defmodule Tq2Web.LicenseViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.LicenseView
  alias Tq2.Payments.LicensePayment, as: LPayment

  import Phoenix.View
  import Ecto.Query

  test "renders show.html", %{conn: conn} do
    license = license()

    content =
      render_to_string(LicenseView, "show.html", conn: conn, license: license, payments: [])

    assert String.contains?(content, String.capitalize(license.status))
    refute String.contains?(content, "<table>")
  end

  test "renders show.html with payments", %{conn: conn} do
    license = license()
    payment = sample_payment()

    content =
      render_to_string(LicenseView, "show.html", conn: conn, license: license, payments: [payment])

    assert String.contains?(content, String.capitalize(license.status))
    assert String.contains?(content, String.capitalize(payment.status))
    assert String.contains?(content, LicenseView.localize(payment.paid_at))
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

  test "money" do
    payment = sample_payment()

    assert LicenseView.money(payment.amount) == "$12.00"
  end

  test "Payment status" do
    payment = sample_payment()

    assert LicenseView.payment_status(payment.status) == "Paid"
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

  defp sample_payment do
    %LPayment{paid_at: Timex.now(), amount: Money.new(1200, :ARS), status: "paid"}
  end
end
