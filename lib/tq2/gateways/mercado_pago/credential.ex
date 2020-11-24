defmodule Tq2.Gateways.MercadoPago.Credential do
  defstruct currency: nil, domain: nil, app_id: nil, user_id: nil, token: nil

  alias Tq2.Gateways.MercadoPago.Credential

  @currencies ~w(ARS CLP COP MXN PEN)

  @doc "Returns a Credential strict given a user_id."
  def for_user_id(user_id) do
    Enum.find_value(@currencies, fn currency ->
      client = currency |> for_currency()

      if client.user_id == user_id, do: client
    end)
  end

  @doc "Returns a Credential strict given a currency."
  def for_currency("ARS") do
    token = mp_config(:ars_token)

    credential_for("ARS", "mercadopago.com.ar", token)
  end

  def for_currency("CLP") do
    token = mp_config(:clp_token)

    credential_for("CLP", "mercadopago.cl", token)
  end

  def for_currency("COP") do
    token = mp_config(:cop_token)

    credential_for("COP", "mercadopago.com.co", token)
  end

  def for_currency("MXN") do
    token = mp_config(:mxn_token)

    credential_for("MXN", "mercadopago.com.mx", token)
  end

  def for_currency("PEN") do
    token = mp_config(:pen_token)

    credential_for("PEN", "mercadopago.com.pe", token)
  end

  defp mp_config(key) do
    Application.get_env(:tq2, :mp)[key]
  end

  defp credential_for(currency, domain, token) do
    %Credential{
      currency: currency,
      domain: domain,
      app_id: Enum.at(String.split(token, "-"), 1),
      user_id: Enum.at(String.split(token, "-"), -1),
      token: token
    }
  end
end
