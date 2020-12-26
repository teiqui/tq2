defmodule Tq2Web.Store.ShareComponent do
  use Tq2Web, :live_component

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
end
