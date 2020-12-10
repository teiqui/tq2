defmodule Tq2Web.HeaderComponent do
  use Tq2Web, :live_component

  alias Tq2.Shops.Store

  defp image(%Store{logo: nil}) do
  end

  defp image(%Store{logo: logo} = store) do
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
