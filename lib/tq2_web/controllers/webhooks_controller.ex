defmodule Tq2Web.WebhookController do
  use Tq2Web, :controller

  alias Tq2.Webhooks
  alias Tq2.Workers.WebhooksJob

  def mercado_pago(conn, params) do
    %{name: "mercado_pago", payload: params}
    |> Webhooks.create_webhook()
    |> enqueue_webhook()

    json(conn, %{})
  end

  defp enqueue_webhook({:ok, webhook}) do
    Exq.enqueue(Exq, "default", WebhooksJob, [webhook.name, webhook.id])
  end

  defp enqueue_webhook({:error, changeset}) do
    Sentry.capture_message("Webhook Error #{changeset.data.name}", extra: changeset.errors)
  end
end
