defmodule Tq2Web.Registration.EmailLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2.Accounts

  describe "render" do
    setup [:create_registration]

    @valid_attrs %{
      name: "some name",
      type: "grocery",
      terms_of_service: true
    }

    def create_registration(_) do
      {:ok, registration} = Accounts.create_registration(@valid_attrs)

      %{registration: registration}
    end

    test "disconnected and connected render", %{conn: conn, registration: registration} do
      path = Routes.registration_email_path(conn, :index, registration)
      {:ok, email_live, html} = live(conn, path)

      assert html =~ "Let&apos;s keep going!"
      assert render(email_live) =~ "Let&apos;s keep going!"
    end

    test "save event", %{conn: conn, registration: registration} do
      path = Routes.registration_email_path(conn, :index, registration)
      {:ok, email_live, _html} = live(conn, path)

      assert email_live
             |> form("form", %{
               registration: %{
                 email: "some@email.com",
                 email_confirmation: "some@email.com"
               }
             })
             |> render_submit() ==
               {:error,
                {:live_redirect,
                 %{kind: :push, to: Routes.registration_password_path(conn, :index, registration)}}}
    end

    test "save event with invalid confirmation", %{conn: conn, registration: registration} do
      path = Routes.registration_email_path(conn, :index, registration)
      {:ok, email_live, _html} = live(conn, path)

      assert email_live
             |> form("form", %{
               registration: %{
                 email: "some@email.com",
                 email_confirmation: "wrong@email.com"
               }
             })
             |> render_submit() =~ "does not match confirmation"
    end
  end
end
