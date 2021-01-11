defmodule Tq2Web.Store.CategoryComponent do
  use Tq2Web, :live_component

  alias Tq2.Inventories.{Category, Item}

  defp image_for(%Category{} = category) do
    category.items
    |> List.first()
    |> image(category)
  end

  defp image(%Item{image: nil}, category) do
    ~E"""
      <svg class="img-fluid rounded"
           viewBox="0 0 150 150"
           width="150"
           height="150"
           xmlns="http://www.w3.org/2000/svg"
           focusable="false"
           role="img"
           aria-label="<%= category.name %>">
        <g>
          <title><%= category.name %></title>
          <rect width="150" height="150" x="0" y="0" fill="#c4c4c4"></rect>
          <text x="50%" y="50%" text-anchor="middle" alignment-baseline="middle" fill="#838383" dy=".3em">
            <%= String.slice(category.name, 0..10) %>
          </text>
        </g>
      </svg>
    """
  end

  defp image(%Item{image: image} = item, category) do
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
      alt: category.name,
      class: "img-fluid rounded"
    )
  end
end
