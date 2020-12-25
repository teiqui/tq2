defmodule Tq2Web.Store.HeaderComponent do
  use Tq2Web, :live_component

  alias Tq2.Shops.Store

  defp image(socket, %Store{logo: nil} = store) do
    path = Routes.static_path(socket, "/images/store_default_logo.svg")

    img_tag(path,
      width: "70",
      height: "70",
      loading: "lazy",
      alt: store.name,
      class: "img-fluid rounded-circle"
    )
  end

  defp image(_socket, %Store{logo: logo} = store) do
    url = Tq2.LogoUploader.url({logo, store}, :thumb)

    set = %{
      url => "1x",
      Tq2.LogoUploader.url({logo, store}, :thumb_2x) => "2x"
    }

    img_tag(url,
      srcset: set,
      width: "70",
      height: "70",
      loading: "lazy",
      alt: store.name,
      class: "img-fluid rounded-circle"
    )
  end
end
