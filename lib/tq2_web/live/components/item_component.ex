defmodule Tq2Web.ItemComponent do
  use Tq2Web, :live_component

  import Tq2Web.ItemView, only: [money: 1]

  alias Tq2.Inventories.Item
  alias Tq2.Transactions.Cart

  defp path(socket, store, item) do
    Routes.item_path(socket, :index, store, item)
  end

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

  defp price(%Cart{lines: []}, item) do
    wrapped_price(:p, item)
  end

  defp price(%Cart{price_type: "regular"}, item) do
    wrapped_price(:p, item)
  end

  defp price(_, item) do
    wrapped_price(:del, item)
  end

  defp promotional_price(socket, %Cart{lines: []}, item) do
    wrapped_promotional_price(socket, :p, item)
  end

  defp promotional_price(socket, %Cart{price_type: "promotional"}, item) do
    wrapped_promotional_price(socket, :p, item)
  end

  defp promotional_price(socket, _cart, item) do
    wrapped_promotional_price(socket, :del, item)
  end

  defp wrapped_price(tag, item) do
    text = money(item.price)

    content_tag(tag, text, class: "small text-truncate text-muted mb-0 mt-2")
  end

  defp wrapped_promotional_price(socket, tag, item) do
    text = money(item.promotional_price)

    image =
      socket
      |> Routes.static_path("/images/favicon.svg")
      |> img_tag(height: 12, width: 12, alt: "Teiqui")
      |> safe_to_string()

    content = [image, text] |> Enum.join() |> raw()

    content_tag(tag, content, class: "h6 text-truncate text-primary font-weight-semi-bold mb-0")
  end
end
