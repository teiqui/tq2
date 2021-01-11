defmodule Tq2Web.WebhookController do
  use Tq2Web, :controller

  alias Tq2.Webhooks
  alias Tq2.Workers.WebhooksJob

  def mercado_pago(conn, params) do
    if params["type"] == "payment" do
      %{name: "mercado_pago", payload: params}
      |> Webhooks.create_webhook()
      |> enqueue_webhook()
    end

    json(conn, %{})
  end

  def stripe(conn, params) do
    enqueue_license_update(params)

    json(conn, %{})
  end

  defp enqueue_webhook({:ok, webhook}) do
    Exq.enqueue(Exq, "default", WebhooksJob, [webhook.name, webhook.id])
  end

  defp enqueue_webhook({:error, changeset}) do
    Sentry.capture_message("Webhook Error #{changeset.data.name}", extra: changeset.errors)
  end

  defp enqueue_license_update(%{"data" => %{"object" => %{"id" => id} = object}}) do
    customer = object["customer"]
    subscription = object["subscription"]

    cond do
      customer || String.starts_with?(id, "cus_") ->
        Exq.enqueue(Exq, "default", Tq2.Workers.LicensesJob, [:customer_id, customer || id])

      subscription || String.starts_with?(id, "sub_") ->
        Exq.enqueue(Exq, "default", Tq2.Workers.LicensesJob, [
          :subscription_id,
          subscription || id
        ])
    end
  end
end
