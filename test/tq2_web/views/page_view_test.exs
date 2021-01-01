defmodule Tq2Web.PageViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.PageView

  import Phoenix.View

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "renders index.html", %{conn: conn} do
    content = render_to_string(PageView, "index.html", conn: conn)

    assert String.contains?(content, "Teiqui price")
  end
end
