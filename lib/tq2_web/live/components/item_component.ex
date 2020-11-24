defmodule Tq2Web.ItemComponent do
  use Tq2Web, :live_component

  alias Tq2.Inventories.Item
  import Tq2Web.ItemView, only: [money: 1]

  defp image(%Item{image: nil}), do: nil

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
