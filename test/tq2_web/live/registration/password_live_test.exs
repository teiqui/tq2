defmodule Tq2Web.Registration.PasswordLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2.Accounts

  describe "render" do
    setup [:create_registration]

    @valid_attrs %{
      name: "some name",
      type: "grocery",
      email: "some@email.com",
      email_confirmation: " soME@email.com",
      terms_of_service: true
    }

    def create_registration(_) do
      {:ok, registration} = Accounts.create_registration(@valid_attrs)

      %{registration: registration}
    end

    test "disconnected and connected render", %{conn: conn, registration: registration} do
      path = Routes.registration_password_path(conn, :index, registration)
      {:ok, password_live, html} = live(conn, path)

      assert html =~ "Yes!"
      assert render(password_live) =~ "Yes!"
    end

    test "save event", %{conn: conn, registration: registration} do
      path = Routes.registration_password_path(conn, :index, registration)
      {:ok, password_live, _html} = live(conn, path)

      password_live
      |> element("form")
      |> render_submit(%{
        registration: %{
          "password" => "123456",
          "password_confirmation" => "123456"
        }
      })

      assert_redirect(password_live, Routes.registration_path(conn, :show, registration))
    end

    test "save event with invalid confirmation", %{conn: conn, registration: registration} do
      path = Routes.registration_password_path(conn, :index, registration)
      {:ok, password_live, _html} = live(conn, path)

      assert password_live
             |> element("form")
             |> render_submit(%{
               registration: %{
                 "password" => "123456",
                 "password_confirmation" => "654321"
               }
             }) =~ "does not match confirmation"
    end
  end
end
