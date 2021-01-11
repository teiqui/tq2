defmodule Tq2Web.PageView do
  use Tq2Web, :view

  alias Tq2.Accounts.License

  defp app_uri do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    url_config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      host: Enum.join([Application.get_env(:tq2, :app_subdomain), url_config[:host]], ".")
    }
  end

  defp teiqui_price_img_tag(conn) do
    path = Routes.static_path(conn, "/images/page/teiqui_price.jpg")
    path_2x = Routes.static_path(conn, "/images/page/teiqui_price_2x.jpg")

    img_tag(path,
      srcset: %{path => "1x", path_2x => "2x"},
      width: "257",
      height: "444",
      loading: "lazy",
      class: "img-fluid",
      alt: dgettext("page", "Teiqui price")
    )
  end

  defp app_img_tag(conn) do
    path = Routes.static_path(conn, "/images/page/app.jpg")
    path_2x = Routes.static_path(conn, "/images/page/app_2x.jpg")

    img_tag(path,
      width: "290",
      srcset: %{path => "1x", path_2x => "2x"},
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

  defp localized_taxes_text("ar") do
    content_tag(:small, dgettext("page", "+ applicable taxes"), class: "text-info")
  end

  defp localized_taxes_text(_), do: content_tag(:small, raw("&nbsp;"))
end
