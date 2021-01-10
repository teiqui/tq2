defmodule Tq2.Gateways.MercadoPago.Webhook do
  alias Tq2.Apps
  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Payments

  def process(webhook) do
    process_by_type(webhook.payload)
  end

  defp process_by_type(%{"type" => "payment", "user_id" => user_id} = payload) do
    client = app_for_user_id(user_id)

    process_payment(client, payload)
  end

  defp process_by_type(_), do: nil

  defp app_for_user_id(user_id), do: Apps.get_mercado_pago_by_user_id(user_id)

  defp process_payment(nil, _), do: {:error, "Not found"}

  defp process_payment(%MPApp{} = app, %{"data.id" => id}) do
    app
    |> MPCredential.for_app()
    |> MPClient.get_payment(id)
    |> MPClient.response_to_payment()
    |> Payments.update_payment(app.account)
  end
end
