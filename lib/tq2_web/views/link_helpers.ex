defmodule Tq2Web.LinkHelpers do
  import Phoenix.HTML, only: [raw: 1]
  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  def icon_link(icon, opts) do
    link opts do
      options = [class: "bi", width: "14", height: "14", fill: "currentColor"]

      content_tag(:svg, options) do
        raw("<use xlink:href=\"/images/bootstrap-icons.svg##{icon}\"/>")
      end
    end
  end
end
