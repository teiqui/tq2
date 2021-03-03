defmodule Tq2Web.PageView do
  use Tq2Web, :view

  alias Tq2.Accounts.License

  import Tq2.Utils.Urls, only: [app_uri: 0]
  import Tq2Web.LayoutView, only: [locale: 0]

  defp app_img_tag(conn) do
    path = Routes.static_path(conn, "/images/page/app.svg")

    img_tag(path,
      width: "290",
      height: "603",
      loading: "lazy",
      class: "img-fluid",
      alt: dgettext("page", "App")
    )
  end

  defp localized_monthly_price(country) do
    price = License.price_for(country)

    "#{price.currency} #{Money.to_string(price, symbol: true)}"
  end

  defp localized_yearly_price(country) do
    price = License.price_for(country, :yearly)

    "#{price.currency} #{Money.to_string(price, symbol: true)}"
  end

  defp localized_save_price(country) do
    price =
      country
      |> License.price_for()
      |> Money.multiply(2)

    "#{price.currency} #{Money.to_string(price, symbol: true)}"
  end

  defp localized_taxes_text("ar") do
    content_tag(:small, dgettext("page", "+ applicable taxes"), class: "text-info")
  end

  defp localized_taxes_text(_), do: content_tag(:small, raw("&nbsp;"))

  defp play_store_app_url do
    "https://play.google.com/store/apps/details?id=com.teiqui.app.twa"
  end

  defp play_store_img_tag do
    locale
    |> play_store_img_url()
    |> img_tag(
      class: "img-fluid ml-lg-n3",
      alt: dgettext("page", "Get it on Google Play"),
      width: "248"
    )
  end

  defp play_store_img_url("es") do
    "https://play.google.com/intl/es-419/badges/static/images/badges/es-419_badge_web_generic.png"
  end

  defp play_store_img_url("en") do
    "https://play.google.com/intl/es-419/badges/static/images/badges/en_badge_web_generic.png"
  end
end
