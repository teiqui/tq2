defmodule Tq2.Gateways.MercadoPago.Credential do
  defstruct token: nil

  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2.Gateways.MercadoPago.Credential

  @credential_urls %{
    "ar" => "https://www.mercadopago.com.ar/developers/panel/",
    "br" => "https://www.mercadopago.com.br/developers/panel/",
    "cl" => "https://www.mercadopago.cl/developers/panel/",
    "co" => "https://www.mercadopago.com.co/developers/panel/",
    "mx" => "https://www.mercadopago.com.mx/developers/panel/",
    "pe" => "https://www.mercadopago.com.pe/developers/panel/",
    "uy" => "https://www.mercadopago.com.uy/developers/panel/"
  }

  @doc "Returns a Credential struct given a MPApp."
  def for_app(%MPApp{data: %{access_token: token}}) do
    %Credential{token: token}
  end

  def credential_url(country) do
    @credential_urls[country]
  end
end
