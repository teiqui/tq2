defmodule Tq2.Gateways.MercadoPago.CredentialTest do
  use Tq2.DataCase

  alias Tq2.Gateways.MercadoPago.Credential

  describe "mercado pago credentials" do
    @client Credential.for_currency("ARS")

    test "by_user_id/1 returns valid client" do
      client = Credential.for_user_id("3333")

      assert %Credential{} = client
      assert "ARS" == client.currency
      assert @client.token == client.token
    end

    test "for_currency/1 returns valid client" do
      client = Credential.for_currency("ARS")

      assert %Credential{} = client
      assert "ARS" == client.currency
      assert @client.token == client.token
    end

    test "for_currency/1 for all valid currencies" do
      Enum.each(~w(ARS CLP COP MXN PEN), fn currency ->
        assert %Credential{} = Credential.for_currency(currency)
      end)
    end
  end
end
