defmodule Tq2.Workers.WebhooksJobTest do
  use Tq2.DataCase

  import Mock

  alias Tq2.Gateways.MercadoPago.Webhook, as: MPWebhook
  alias Tq2.Webhooks
  alias Tq2.Workers.WebhooksJob

  describe "mercado pago" do
    test "perform/2 should process webhook" do
      {:ok, webhook} =
        %{
          name: "mercado_pago",
          payload: %{"user_id" => 123}
        }
        |> Webhooks.create_webhook()

      with_mock MPWebhook, process: fn _ -> {} end do
        "mercado_pago" |> WebhooksJob.perform(webhook.id)

        assert_called(MPWebhook.process(webhook))
      end
    end
  end
end
