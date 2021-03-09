defmodule Tq2.Gateways.Conekta.WebhookTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [create_cart: 0]

  alias Tq2.Gateways.Conekta.Webhook, as: CktWebhookClient
  alias Tq2.Payments
  alias Tq2.Webhooks.Conekta, as: CktWebhook

  describe "conekta webhooks" do
    test "process/1 returns nil for invalid webhook" do
      refute CktWebhookClient.process(%CktWebhook{})
    end

    test "process/1 returns nil for invalid type" do
      webhook = %CktWebhook{
        payload: %{"type" => "unknown"}
      }

      refute CktWebhookClient.process(webhook)
    end

    test "process/1 returns updated payment for valid webhook" do
      webhook = %CktWebhook{
        name: "conekta",
        payload: %{
          "type" => "order.paid",
          "data" => %{
            "object" => %{
              "charges" => %{
                "data" => [
                  %{
                    "order_id" => "ord_1",
                    "channel" => %{"checkout_request_id" => "ext_123"}
                  }
                ]
              }
            }
          }
        }
      }

      # TODO: change for the real app
      # app_conekta_fixture()

      cart = create_cart()

      {:ok, original_payment} =
        Payments.create_payment(
          cart,
          %{
            amount: Tq2.Transactions.Cart.total(cart),
            kind: "conekta",
            status: "pending",
            external_id: "ext_123"
          }
        )

      # Update payment & create order
      with_mock HTTPoison, mock() do
        {:ok, payment} = CktWebhookClient.process(webhook)

        assert payment.id == original_payment.id
        assert payment.status == "paid"
        assert payment.order.id
        assert payment.order.data.paid
      end
    end

    defp mock do
      json_body =
        Jason.encode!(%{
          "id" => "ord_123",
          "charges" => %{
            "data" => [
              %{
                "amount" => 1000,
                "currency" => "MXN",
                "order_id" => "ord_123",
                "status" => "paid",
                "paid_at" => System.os_time(:second),
                "channel" => %{"checkout_request_id" => "ext_123"}
              }
            ]
          }
        })

      [
        get: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: 200, body: json_body}}
        end
      ]
    end
  end
end
