defmodule Tq2Web.Store.CategoryComponent do
  use Tq2Web, :live_component

  alias Tq2.Inventories.{Category, Item}

  defp image_for(%Category{} = category) do
    category.items
    |> Enum.filter(& &1.image)
    |> Enum.take(4)
    |> one_or_four_items(category)
  end

  defp default_image(category) do
    ~E"""
      <svg class="img-fluid rounded"
           viewBox="0 0 148 148"
           width="148"
           height="148"
           xmlns="http://www.w3.org/2000/svg"
           focusable="false"
           role="img"
           aria-label="<%= category.name %>">
        <g>
          <title><%= category.name %></title>
          <rect width="148" height="148" x="0" y="0" fill="#c4c4c4"></rect>
          <text x="50%" y="50%" text-anchor="middle" alignment-baseline="middle" fill="#838383" dy=".3em">
            <%= String.slice(category.name, 0..10) %>
          </text>
        </g>
      </svg>
    """
  end

  defp image(%Item{image: image} = item, category, size \\ 148, extra_classes \\ nil) do
    url = Tq2.ImageUploader.url({image, item}, :thumb)

    set = %{
      url => "1x",
      Tq2.ImageUploader.url({image, item}, :thumb_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "#{size}",
      height: "#{size}",
      loading: "lazy",
      alt: category.name,
      class: "img-fluid rounded #{extra_classes}"
    )
  end

  defp one_or_four_items([], category) do
    default_image(category)
  end

  defp one_or_four_items([item], category) do
    item |> image(category)
  end

  defp one_or_four_items([item | _] = items, category) when length(items) < 4 do
    one_or_four_items([item], category)
  end

  defp one_or_four_items([a, b, c, d], category) do
    content_tag(:div) do
      [
        content_tag(:div, class: "row") do
          [
            content_tag(:div, image(a, category, 70), class: "col mr-n2"),
            content_tag(:div, image(b, category, 70), class: "col ml-n2")
          ]
        end,
        content_tag(:div, class: "row mt-2") do
          [
            content_tag(:div, image(c, category, 70), class: "col mr-n2"),
            content_tag(:div, image(d, category, 70), class: "col ml-n2")
          ]
        end
      ]
    end
  end
end
