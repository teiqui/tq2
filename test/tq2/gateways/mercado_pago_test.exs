defmodule Tq2.Gateways.MercadoPagoTest do
  use Tq2.DataCase

  import Mock

  alias Tq2.Gateways.MercadoPago
  alias Tq2.Gateways.MercadoPago.Credential

  describe "mercado pago" do
    @default_payment %{
      id: 123,
      external_reference: "123",
      transaction_amount: 12.0,
      date_approved: Timex.now(),
      status: "approved"
    }
    @client Credential.for_currency("ARS")

    test "min_amount_for/1 returns min amount for currency" do
      assert 2.0 == MercadoPago.min_amount_for("ARS")
      assert 1000.0 == MercadoPago.min_amount_for("COP")
    end

    test "get_payment/2 returns payment" do
      with_mock HTTPoison, mock_get_with() do
        payment = @client |> MercadoPago.get_payment("123")

        assert %{} = payment
        assert 123 == payment["id"]
        assert "approved" == payment["status"]
      end
    end

    test "last_payment_for_reference/2 returns parsed payment" do
      mocked_fn = %{"results" => [@default_payment]} |> mock_get_with()

      with_mock HTTPoison, mocked_fn do
        payment =
          @client
          |> MercadoPago.last_payment_for_reference(@default_payment.external_reference)

        assert %{} = payment
        assert 123 == payment.external_id
        assert :paid == payment.status
        assert %DateTime{} = payment.paid_at
      end
    end

    test "marketplace_association_link/1 returns valid url" do
      link = @client |> MercadoPago.marketplace_association_link()

      assert link =~ "https://auth.mercadopago.com.ar"
      # token app_id
      assert link =~ "client_id=3333"
      # TODO: Change for the real url
      assert link =~ "redirect_uri=marketplace"
    end

    test "associate_marketplace/2 returns valid marketplace map" do
      default_marketplace = %{
        access_token: "MARKETPLACE_SELLER_TOKEN",
        public_key: "PUBLIC_KEY",
        refresh_token: "TG-XXXXXXXXX-XXXXX",
        live_mode: true,
        user_id: "123",
        token_type: "bearer",
        expires_in: 15_552_000,
        scope: "offline_access payments write"
      }

      mocked_fn = default_marketplace |> mock_post_with()

      with_mock HTTPoison, mocked_fn do
        marketplace = @client |> MercadoPago.associate_marketplace("111")

        assert %{} = marketplace
        assert default_marketplace.access_token == marketplace["access_token"]
        assert default_marketplace.refresh_token == marketplace["refresh_token"]
      end
    end

    defp mock_get_with(%{} = body \\ @default_payment, code \\ 200) do
      json_body = body |> Jason.encode!()

      [
        get: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: code, body: json_body}}
        end
      ]
    end

    defp mock_post_with(%{} = body, code \\ 201) do
      json_body = body |> Jason.encode!()

      [
        post: fn _url, _params, _headers ->
          {:ok, %HTTPoison.Response{status_code: code, body: json_body}}
        end
      ]
    end
  end
end
