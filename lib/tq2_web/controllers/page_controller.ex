defmodule Tq2Web.PageController do
  use Tq2Web, :controller

  import Tq2.Utils.CountryCurrency, only: [guess_country_from_ip: 1]

  def index(conn, %{"country" => country}) do
    conn |> render_with_country(country)
  end

  def index(conn, _params) do
    case guess_country_from_ip(conn.remote_ip) do
      nil -> render_with_country(conn)
      country -> conn |> redirect(to: Routes.page_path(conn, :index, String.upcase(country)))
    end
  end

  defp render_with_country(conn, country \\ "") do
    conn
    |> put_layout("page.html")
    |> render("index.html", country: String.downcase(country))
  end
end
