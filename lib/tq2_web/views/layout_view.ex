defmodule Tq2Web.LayoutView do
  use Tq2Web, :view

  import Phoenix.Controller, only: [get_flash: 2, current_path: 1]

  def locale do
    Tq2Web.Gettext
    |> Gettext.get_locale()
    |> String.replace(~r/_\w+/, "")
  end

  def menu_item(conn, [to: to], do: content) do
    current = current_path(conn)

    html_class =
      if String.starts_with?(current, to) do
        "nav-item active"
      else
        "nav-item"
      end

    content_tag(:li, class: html_class) do
      link(to: to, class: "nav-link", do: content)
    end
  end
end
