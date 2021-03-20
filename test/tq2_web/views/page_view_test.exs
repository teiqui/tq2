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
    content = render_to_string(PageView, "index.html", conn: conn, country: nil)

    assert String.contains?(content, "Teiqui price")
    assert String.contains?(content, "USD $3.99")
  end

  test "renders index.html for country with payment option", %{conn: conn} do
    content = render_to_string(PageView, "index.html", conn: conn, country: "ar")

    assert String.contains?(content, "Teiqui price")
    assert String.contains?(content, "ARS $499.0")
    assert String.contains?(content, "Teiqui offers different payment platforms")
    assert String.contains?(content, "mercadopago.svg")
  end

  test "renders index.html for country without payment option", %{conn: conn} do
    content = render_to_string(PageView, "index.html", conn: conn, country: "us")

    assert String.contains?(content, "Teiqui price")
    assert String.contains?(content, "USD $3.99")
    refute String.contains?(content, "Teiqui offers different payment platforms")
  end
end
