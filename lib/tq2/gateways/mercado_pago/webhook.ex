defmodule Tq2.Gateways.MercadoPago.Webhook do
  alias Tq2.Accounts
  alias Tq2.Apps
  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Payments

  def process(webhook) do
    process_by_type(webhook.payload)
  end

  defp process_by_type(%{"type" => "payment", "user_id" => user_id} = payload) do
    client = MPCredential.for_user_id(user_id) || app_for_user_id(user_id)

    process_payment(client, payload)
  end

  defp process_by_type(_), do: nil

  defp app_for_user_id(user_id), do: Apps.get_mercado_pago_by_user_id(user_id)

  defp process_payment(nil, _), do: {:error, "Not found"}

  # License
  defp process_payment(%MPCredential{} = credential, %{"data.id" => id}) do
    ext_payment = MPClient.get_payment(credential, id)
    account = Accounts.get_account_by_license_reference!(ext_payment["external_reference"])

    ext_payment
    |> MPClient.response_to_payment()
    |> Payments.create_or_update_license_payment(account)
  end

  # Marketplace
  defp process_payment(%MPApp{} = app, %{"data.id" => id}) do
    app
    |> MPCredential.for_app()
    |> MPClient.get_payment(id)
    |> MPClient.response_to_payment()
    |> Payments.update_payment(app.account)
  end
end
