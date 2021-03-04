defmodule Tq2Web.Registration.NewLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  describe "render" do
    test "disconnected and connected render", %{conn: conn} do
      path = Routes.registration_path(conn, :index)
      {:ok, name_live, html} = live(conn, path)

      assert html =~ "Create your Teiqui online store"
      assert render(name_live) =~ "Create your Teiqui online store"
    end

    test "save event", %{conn: conn} do
      path = Routes.registration_path(conn, :index)
      {:ok, name_live, _html} = live(conn, path)

      response =
        name_live
        |> form("form", %{
          registration: %{
            name: "some name",
            type: "grocery",
            email: "some@email.com",
            password: "123456"
          }
        })
        |> render_submit()

      assert {:error, {:redirect, %{to: to}}} = response

      [_, _, registration_uuid] = to |> String.split("/")

      assert_redirect(name_live, Routes.registration_path(conn, :show, registration_uuid))

      license = license_from_registration(registration_uuid)
      trial_until = Timex.today() |> Timex.shift(days: 14)

      assert license.paid_until == trial_until
    end

    test "save event with extended trial campaign", %{conn: conn} do
      path = Routes.registration_path(conn, :index, %{"utm_campaign" => "extended_trial"})
      {:ok, name_live, _html} = live(conn, path)

      response =
        name_live
        |> form("form", %{
          registration: %{
            name: "some name",
            type: "grocery",
            email: "some@email.com",
            password: "123456"
          }
        })
        |> render_submit()

      assert {:error, {:redirect, %{to: to}}} = response

      [_, _, registration_uuid] = to |> String.split("/")

      assert_redirect(name_live, Routes.registration_path(conn, :show, registration_uuid))

      license = license_from_registration(registration_uuid)
      trial_until = Timex.today() |> Timex.shift(days: 30)

      assert license.paid_until == trial_until
    end

    test "save event with invalid data", %{conn: conn} do
      path = Routes.registration_path(conn, :index)
      {:ok, name_live, _html} = live(conn, path)

      assert name_live
             |> form("form", %{
               registration: %{
                 name: "",
                 type: "",
                 email: "",
                 password: ""
               }
             })
             |> render_submit() =~ "can&#39;t be blank"
    end
  end

  defp license_from_registration(uuid) do
    uuid
    |> Tq2.Accounts.get_registration!()
    |> Map.fetch!(:account)
    |> Tq2.Accounts.get_license!()
  end
end
