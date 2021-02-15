defmodule Tq2Web.Account.LicenseLiveTest do
  use Tq2Web.ConnCase

  import Mock
  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [init_test_session: 1]

  alias Tq2.Accounts
  alias Tq2.Gateways.Stripe, as: StripeClient

  describe "render" do
    setup [:init_test_session]

    test "render trial license", %{conn: conn, session: %{account: %{license: license}}} do
      path = Routes.license_path(conn, :index)
      {:ok, _license_live, html} = live(conn, path)

      assert html =~ "License"
      assert html =~ "Trial"
      assert html =~ Timex.format!(license.paid_until, "%m/%d/%y", :strftime)
      assert html =~ "Monthly pay"
      assert html =~ "Yearly pay"
    end

    test "render loading after click on monthly", %{conn: conn} do
      path = Routes.license_path(conn, :index)
      {:ok, license_live, _html} = live(conn, path)

      mock = [create_customer: fn license -> license end]

      with_mock StripeClient, mock do
        content =
          license_live
          |> element("#license-links [phx-click=\"monthly\"]")
          |> render_click()

        assert content =~ "spinner"
      end
    end

    test "render loading while subscription is loaded", %{
      conn: conn,
      session: %{account: %{license: license}}
    } do
      {:ok, _} =
        license |> Accounts.update_license(%{customer_id: "cus_123", subscription_id: "sub_123"})

      path = Routes.license_path(conn, :index)
      {:ok, _license_live, html} = live(conn, path)

      assert html =~ "spinner"
    end

    test "push event with subscription session id", %{
      conn: conn,
      session: %{account: %{license: license}}
    } do
      {:ok, _} = Accounts.update_license(license, %{customer_id: "cus_123"})

      path = Routes.license_path(conn, :index)
      {:ok, license_live, _html} = live(conn, path)

      mock = [create_subscription_session: fn _ -> {:ok, "123"} end]

      with_mock StripeClient, mock do
        content =
          license_live
          |> element("#license-links [phx-click=\"monthly\"]")
          |> render_click()

        assert content =~ "spinner"

        payload =
          receive do
            {_, {:push_event, "redirect-to-checkout", payload}} -> payload
          after
            1_000 -> assert nil
          end

        assert payload[:id] == "123"
      end
    end

    test "customer info link", %{conn: conn, session: %{account: %{license: license}}} do
      {:ok, _} =
        Accounts.update_license(license, %{customer_id: "cus_123", subscription_id: "sub_123"})

      mock = [
        find_subscription: fn _license ->
          %{plan: %{currency: "ars", amount: 49900, interval: "month"}}
        end,
        create_billing_session: fn _license -> {:ok, "https://stripe.com"} end
      ]

      with_mock StripeClient, mock do
        path = Routes.license_path(conn, :index)
        {:ok, license_live, html} = live(conn, path)

        assert html =~ "spinner"

        receive do
          {:fetch_subscription} -> nil
        after
          1_000 -> nil
        end

        assert render(license_live) =~ "phx-click=\"customer-info\""
        assert render(license_live) =~ "Monthly - ARS $499.0"

        license_live
        |> element("#license-links [phx-click=\"customer-info\"]")
        |> render_click()

        to =
          receive do
            {_, {:redirect, _, %{to: to}}} -> to
          after
            1_000 -> nil
          end

        assert to == "https://stripe.com"
      end
    end
  end
end
