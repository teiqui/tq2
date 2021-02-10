defmodule Tq2Web.Store.ShareComponent do
  use Tq2Web, :live_component

  import Tq2.Utils.Urls, only: [store_uri: 0]

  defp whatsapp_share_url(store, token) do
    url =
      store_uri() |> Routes.counter_url(:index, store, referral: token, utm_source: "whatsapp")

    URI.to_string(%URI{
      host: "wa.me",
      scheme: "https",
      query:
        URI.encode_query(%{text: dgettext("stores", "Hey, check our store!\n\n%{url}", url: url)})
    })
  end

  defp facebook_share_url(store, token) do
    url =
      store_uri() |> Routes.counter_url(:index, store, referral: token, utm_source: "facebook")

    URI.to_string(%URI{
      host: "www.facebook.com",
      scheme: "https",
      path: "/sharer.php",
      query: URI.encode_query(%{u: url})
    })
  end

  defp telegram_share_url(store, token) do
    url =
      store_uri()
      |> Routes.counter_url(:index, store, referral: token, utm_source: "telegram")

    URI.to_string(%URI{
      host: "telegram.me",
      scheme: "https",
      path: "/share/url",
      query: URI.encode_query(%{url: url})
    })
  end

  defp icon_tag(icon) do
    content_tag(:i, "", class: "bi-#{icon}")
  end
end
