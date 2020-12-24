defmodule Tq2.Gateways.MercadoPago.WebhookTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [default_account: 0, create_session: 0]

  alias Tq2.Apps
  alias Tq2.Gateways.MercadoPago.Webhook, as: MPWebhookClient
  alias Tq2.Payments.LicensePayment, as: LPayment
  alias Tq2.Webhooks.MercadoPago, as: MPWebhook

  describe "mercado pago webhooks" do
    @default_payment %{
      id: 888,
      external_reference: "cart-123",
      transaction_amount: 12.0,
      date_approved: Timex.now(),
      status: "approved",
      currency_id: "ARS"
    }

    test "process/1 returns nil for invalid webhook" do
      refute MPWebhookClient.process(%MPWebhook{})
    end

    test "process/1 returns nil for invalid user_id" do
      webhook = %MPWebhook{
        payload: %{"user_id" => "1", "type" => "payment"}
      }

      assert {:error, "Not found"} = MPWebhookClient.process(webhook)
    end

    test "process/1 returns created license payment for valid webhook" do
      license = default_account().license

      webhook = %MPWebhook{
        name: "mercado_pago",
        payload: %{
          "type" => "payment",
          "user_id" => "3333",
          "data.id" => "888"
        }
      }

      payment_mock = %{@default_payment | external_reference: license.reference}

      with_mock HTTPoison, mock_get_with(payment_mock) do
        {:ok, %LPayment{} = payment} = MPWebhookClient.process(webhook)

        amount =
          payment_mock.transaction_amount
          |> Money.parse!(payment_mock.currency_id)

        assert payment.amount == amount
        assert payment.status == "paid"
      end
    end

    test "process/1 returns created payment for valid webhook" do
      mp_attrs = %{
        name: "mercado_pago",
        data: %{
          "access_token" => "1234",
          "user_id" => 123
        }
      }

      {:ok, _app} = create_session() |> Apps.create_app(mp_attrs)

      webhook = %MPWebhook{
        name: "mercado_pago",
        payload: %{
          "type" => "payment",
          "user_id" => "123",
          "data.id" => "888"
        }
      }

      with_mock HTTPoison, mock_get_with(@default_payment) do
        "TBD" = MPWebhookClient.process(webhook)
      end
    end

    defp mock_get_with(%{} = body, code \\ 200) do
      json_body = body |> Jason.encode!()

      [
        get: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: code, body: json_body}}
        end
      ]
    end
  end
end
