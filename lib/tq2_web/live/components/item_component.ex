defmodule Tq2Web.ItemComponent do
  use Tq2Web, :live_component

  alias Tq2.Inventories.Item
  import Tq2Web.ItemView, only: [money: 1]

  defp image(%Item{image: nil} = item) do
    ~E"""
      <svg class="card-img-top embed-responsive-item"
           viewBox="0 0 150 150"
           width="150"
           height="150"
           xmlns="http://www.w3.org/2000/svg"
           focusable="false"
           role="img"
           aria-label="<%= item.name %>">
        <g>
          <title><%= item.name %></title>
          <rect width="150" height="150" x="0" y="0" fill="#c4c4c4"></rect>
          <text x="50%" y="50%" text-anchor="middle" alignment-baseline="middle" fill="#838383" dy=".3em">
            <%= String.slice(item.name, 0..10) %>
          </text>
        </g>
      </svg>
    """
  end

  defp image(%Item{image: image} = item) do
    url = Tq2.ImageUploader.url({image, item}, :thumb)

    set = %{
      url => "1x",
      Tq2.ImageUploader.url({image, item}, :thumb_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "150",
      height: "150",
      loading: "lazy",
      alt: item.name,
      class: "card-img-top embed-responsive-item"
    )
  end
end
