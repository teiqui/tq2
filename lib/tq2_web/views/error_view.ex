defmodule Tq2Web.ErrorView do
  use Tq2Web, :view

  import Plug.Conn, only: [halt: 1, put_status: 2]

  import Tq2Web.LayoutView, only: [locale: 0]

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render("500.html", assigns)
  end

  def render_404(conn) do
    conn
    |> put_status(404)
    |> Phoenix.Controller.put_view(__MODULE__)
    |> Phoenix.Controller.render("404.html")
    |> halt()
  end
end
