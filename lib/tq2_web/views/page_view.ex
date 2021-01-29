defmodule Tq2Web.PageView do
  use Tq2Web, :view

  alias Tq2.Accounts.License

  import Tq2.Utils.Urls, only: [app_uri: 0]

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
end
