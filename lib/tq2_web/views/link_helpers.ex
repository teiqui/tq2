defmodule Tq2Web.LinkHelpers do
  import Phoenix.HTML, only: [raw: 1]
  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  def icon_link(icon, [{:text, text} | opts]) do
    {:safe, icon} = icon_tag(icon)

    raw("#{icon} #{text}") |> link(opts)
  end

  def icon_link(icon, opts) do
    icon
    |> icon_tag()
    |> link(opts)
  end

  def link_to_clipboard([{:icon, icon}, {:text, text} | opts]) do
    id = text |> String.replace(~r"[^A-z0-9]+", "-")

    opts =
      opts ++
        [
          to: "#",
          id: "#{id}-copy-to-clipboard",
          data_text: text,
          phx_hook: "CopyToClipboard"
        ]

    icon_link(icon, opts)
  end

  defp icon_tag(icon) do
    content_tag(:i, nil, class: "bi-#{icon}")
  end
end
