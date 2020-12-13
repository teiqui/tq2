defmodule Tq2.Workers.WebhooksJob do
  alias Tq2.Webhooks
  alias Tq2.Gateways.MercadoPago.Webhook, as: MPWebhook

  def perform("mercado_pago", webhook_id) do
    "mercado_pago"
    |> Webhooks.get_webhook(webhook_id)
    |> MPWebhook.process()
  rescue
    ex ->
      # TODO: Change to set_context when it's fixed
      # https://github.com/getsentry/sentry-elixir/issues/349
      Sentry.capture_exception(ex,
        stacktrace: __STACKTRACE__,
        extra: %{mercado_pago: webhook_id},
        tags: %{worker: __MODULE__}
      )

      raise ex
  end
end
