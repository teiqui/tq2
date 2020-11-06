defmodule Tq2Web.SessionViewTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.View

  alias Tq2Web.SessionView

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "renders new.html", %{conn: conn} do
    content = render_to_string(SessionView, "new.html", conn: conn)

    assert String.contains?(content, "Login")
  end
end
