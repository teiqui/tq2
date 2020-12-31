defmodule Tq2.Gateways.MercadoPago.WebhookTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [default_account: 0, create_session: 0]

  alias Tq2.Apps
  alias Tq2.Gateways.MercadoPago.Webhook, as: MPWebhookClient
  alias Tq2.Payments
  alias Tq2.Payments.LicensePayment, as: LPayment
  alias Tq2.Webhooks.MercadoPago, as: MPWebhook

  describe "mercado pago webhooks" do
    @default_payment %{
      id: 888,
      external_reference: "tq2-mp-cart-123",
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

      webhook = %MPWebhook{
        name: "mercado_pago",
        payload: %{
          "type" => "payment",
          "user_id" => "123",
          "data.id" => "888"
        }
      }

      session = create_session()

      {:ok, _app} = session |> Apps.create_app(mp_attrs)

      cart = cart_fixture(session)

      amount =
        Money.parse!(
          "#{@default_payment.transaction_amount}",
          @default_payment.currency_id
        )

      {:ok, original_payment} =
        Payments.create_payment(
          cart,
          %{
            amount: amount,
            kind: "mercado_pago",
            status: "pending",
            external_id: @default_payment.external_reference
          }
        )

      # Update payment & create order
      with_mock HTTPoison, mock_get_with(@default_payment) do
        {:ok, payment} = MPWebhookClient.process(webhook)

        assert payment.id == original_payment.id
        assert payment.status == "paid"
        assert payment.order.id
        assert payment.order.data.paid
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

    defp cart_fixture(session) do
      {:ok, visit} =
        Tq2.Analytics.create_visit(%{
          slug: "test",
          token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
          referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
          utm_source: "whatsapp",
          data: %{
            ip: "127.0.0.1"
          }
        })

      {:ok, cart} =
        Tq2.Transactions.create_cart(
          session.account,
          %{
            token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
            price_type: "promotional",
            visit_id: visit.id
          }
        )

      {:ok, item} =
        Tq2.Inventories.create_item(session, %{
          sku: "some sku",
          name: "some name",
          visibility: "visible",
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS)
        })

      {:ok, line} =
        Tq2.Transactions.create_line(cart, %{
          name: "some name",
          quantity: 3,
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS),
          item: item
        })

      %{cart | lines: [line]}
    end
  end
end
