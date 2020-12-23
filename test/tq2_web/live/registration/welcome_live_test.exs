defmodule Tq2Web.Registration.WelcomeLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  describe "render" do
    test "disconnected and connected render", %{conn: conn} do
      path = Routes.welcome_path(conn, :index)
      {:ok, welcome_live, html} = live(conn, path)

      assert html =~ "Welcome!"
      assert render(welcome_live) =~ "Welcome!"
    end
  end
end
