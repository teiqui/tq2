defmodule Tq2Web.EmailView do
  use Tq2Web, :view

  alias Tq2.Transactions.Cart

  defp base_uri do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    url_config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      port: url_config[:port],
      host: Enum.join([Application.get_env(:tq2, :app_subdomain), url_config[:host]], ".")
    }
  end

  defp format_money(%Money{} = money) do
    Money.to_string(money, symbol: true)
  end

  defp cart_total(%Cart{} = cart) do
    cart
    |> Cart.total()
    |> format_money()
  end

  defp line_total(cart, line) do
    Cart.line_total(cart, line) |> format_money()
  end
end
