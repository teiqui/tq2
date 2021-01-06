defmodule Tq2Web.LinkHelpers do
  import Phoenix.HTML, only: [raw: 1]
  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  alias Tq2Web.Router.Helpers, as: Routes

  def icon_link(conn, icon, [{:text, text} | opts]) do
    {:safe, icon_svg} = icon_tag(conn, icon)

    raw("#{icon_svg} #{text}") |> link(opts)
  end

  def icon_link(conn, icon, opts) do
    conn
    |> icon_tag(icon)
    |> link(opts)
  end

  def link_to_clipboard(conn, [{:icon, icon}, {:text, text} | opts]) do
    id = text |> String.replace(~r"[^A-z0-9]+", "-")

    opts =
      opts ++
        [
          to: "#",
          id: "#{id}-copy-to-clipboard",
          data_text: text,
          phx_hook: "CopyToClipboard"
        ]

    icon_link(conn, icon, opts)
  end

  defp icon_tag(conn, icon) do
    options = [class: "bi", width: "14", height: "14", fill: "currentColor"]
    icon_path = Routes.static_path(conn, "/images/bootstrap-icons.svg##{icon}")

    content_tag(:svg, options) do
      raw("<use xlink:href=\"#{icon_path}\"/>")
    end
  end
end
