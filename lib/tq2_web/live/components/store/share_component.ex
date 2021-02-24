defmodule Tq2Web.Store.ShareComponent do
  use Tq2Web, :live_component

  import Tq2.Utils.Urls, only: [store_uri: 0]

  defp whatsapp_share_url(store, token, nil) do
    store_uri()
    |> Routes.counter_url(:index, store, referral: token, utm_source: "whatsapp")
    |> whatsapp_share_url()
  end

  defp whatsapp_share_url(store, token, item) do
    store_uri()
    |> Routes.item_url(:index, store, item, referral: token, utm_source: "whatsapp")
    |> whatsapp_share_url()
  end

  defp whatsapp_share_url(url) do
    URI.to_string(%URI{
      host: "wa.me",
      scheme: "https",
      query:
        URI.encode_query(%{text: dgettext("stores", "Hey, check this out!\n\n%{url}", url: url)})
    })
  end

  defp facebook_share_url(store, token, nil) do
    store_uri()
    |> Routes.counter_url(:index, store, referral: token, utm_source: "facebook")
    |> facebook_share_url()
  end

  defp facebook_share_url(store, token, item) do
    store_uri()
    |> Routes.item_url(:index, store, item, referral: token, utm_source: "facebook")
    |> facebook_share_url()
  end

  defp facebook_share_url(url) do
    URI.to_string(%URI{
      host: "www.facebook.com",
      scheme: "https",
      path: "/sharer.php",
      query: URI.encode_query(%{u: url})
    })
  end

  defp telegram_share_url(store, token, nil) do
    store_uri()
    |> Routes.counter_url(:index, store, referral: token, utm_source: "telegram")
    |> telegram_share_url()
  end

  defp telegram_share_url(store, token, item) do
    store_uri()
    |> Routes.item_url(:index, store, item, referral: token, utm_source: "telegram")
    |> telegram_share_url()
  end

  defp telegram_share_url(url) do
    URI.to_string(%URI{
      host: "telegram.me",
      scheme: "https",
      path: "/share/url",
      query: URI.encode_query(%{url: url})
    })
  end

  defp clipboard_share_url(store, token, nil) do
    Routes.counter_url(store_uri(), :index, store, referral: token, utm_source: "clipboard")
  end

  defp clipboard_share_url(store, token, item) do
    Routes.item_url(store_uri(), :index, store, item, referral: token, utm_source: "clipboard")
  end

  defp other_app_share_url(store, token, nil) do
    Routes.counter_url(store_uri(), :index, store, referral: token, utm_source: "other_app")
  end

  defp other_app_share_url(store, token, item) do
    Routes.item_url(store_uri(), :index, store, item, referral: token, utm_source: "other_app")
  end

  defp icon_tag(icon) do
    content_tag(:i, nil, class: "bi-#{icon}")
  end
end
