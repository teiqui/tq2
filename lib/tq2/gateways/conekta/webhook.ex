defmodule Tq2.Gateways.Conekta.Webhook do
  alias Tq2.Gateways.Conekta, as: CktClient
  alias Tq2.Payments

  def process(webhook) do
    process_by_type(webhook.payload)
  end

  defp process_by_type(%{"type" => "order.paid"} = payload) do
    charge =
      payload
      |> get_in(["data", "object", "charges", "data"])
      |> List.first()

    case charge do
      %{"order_id" => order_id, "channel" => %{"checkout_request_id" => id}} ->
        get_payment_and_process(id, order_id)

      _ ->
        nil
    end
  end

  defp process_by_type(_), do: nil

  defp get_payment_and_process(id, order_id) do
    case Payments.get_payment_by_external_id(id) do
      nil -> nil
      payment -> payment |> get_app() |> process_payment(order_id, payment)
    end
  end

  defp get_app(%{account: _account}) do
    # TODO: Change for the real app
    # account |> Apps.get_app("conekta")
    %{data: %{api_key: "123"}}
  end

  defp process_payment(nil, _order_id, _payment), do: {:error, "Not found"}

  defp process_payment(%{} = app, order_id, payment) do
    app
    |> CktClient.get_order(order_id)
    |> CktClient.response_to_payment()
    |> Payments.update_payment_by_external_id(payment.account)
  end
end
