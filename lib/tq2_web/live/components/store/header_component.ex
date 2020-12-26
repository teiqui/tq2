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

  defp base_uri do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    url_config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      port: url_config[:port],
      host:
        Enum.join(
          [
            Application.get_env(:tq2, :store_subdomain),
            url_config[:host]
          ],
          "."
        )
    }
  end

  defp whatsapp_share_url(store, token) do
    url = base_uri() |> Routes.counter_url(:index, store, referral: token, utm_source: "whatsapp")

    URI.to_string(%URI{
      host: "wa.me",
      scheme: "https",
      query:
        URI.encode_query(%{text: dgettext("stores", "Hey, check our store!\n\n%{url}", url: url)})
    })
  end

  defp facebook_share_url(store, token) do
    url = base_uri() |> Routes.counter_url(:index, store, referral: token, utm_source: "facebook")

    URI.to_string(%URI{
      host: "www.facebook.com",
      scheme: "https",
      path: "/sharer.php",
      query: URI.encode_query(%{u: url})
    })
  end

  defp caret_direction(conn, true), do: icon_tag(conn, "caret-up")
  defp caret_direction(conn, _), do: icon_tag(conn, "caret-down")

  defp icon_tag(conn, icon) do
    options = [class: "bi", width: "14", height: "14", fill: "currentColor"]
    icon_path = Routes.static_path(conn, "/images/bootstrap-icons.svg##{icon}")

    content_tag(:svg, options) do
      raw("<use xlink:href=\"#{icon_path}\"/>")
    end
  end
end
