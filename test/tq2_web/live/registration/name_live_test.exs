defmodule Tq2Web.Registration.NameLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  describe "render" do
    test "disconnected and connected render", %{conn: conn} do
      path = Routes.registration_path(conn, :index)
      {:ok, name_live, html} = live(conn, path)

      assert html =~ "Let&apos;s create your account"
      assert render(name_live) =~ "Let&apos;s create your account"
    end

    test "save event", %{conn: conn} do
      path = Routes.registration_path(conn, :index)
      {:ok, name_live, _html} = live(conn, path)

      response =
        name_live
        |> element("form")
        |> render_submit(%{
          registration: %{
            "name" => "some name",
            "type" => "grocery"
          }
        })

      assert {:error, {:live_redirect, %{kind: :push, to: to}}} = response

      [_, _, registration_uuid, _] = to |> String.split("/")

      assert Routes.registration_email_path(conn, :index, registration_uuid) == to
    end
  end
end
