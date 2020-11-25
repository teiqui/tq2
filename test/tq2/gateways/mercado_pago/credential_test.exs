defmodule Tq2.Gateways.MercadoPago.CredentialTest do
  use Tq2.DataCase

  alias Tq2.Gateways.MercadoPago.Credential

  describe "mercado pago credentials" do
    @credential Credential.for_currency("ARS")

    test "by_user_id/1 returns valid credentials" do
      credential = Credential.for_user_id("3333")

      assert %Credential{} = credential
      assert "ARS" == credential.currency
      assert @credential.token == credential.token
    end

    test "for_currency/1 returns valid credentials" do
      credential = Credential.for_currency("ARS")

      assert %Credential{} = credential
      assert "ARS" == credential.currency
      assert @credential.token == credential.token
    end

    test "for_currency/1 works for all valid currencies" do
      Enum.each(~w(ARS CLP COP MXN PEN), fn currency ->
        assert %Credential{} = Credential.for_currency(currency)
      end)
    end

    test "for_country/1 returns valid credentials" do
      credential = Credential.for_country("ar")

      assert %Credential{} = credential
      assert "ARS" == credential.currency
      assert @credential.token == credential.token
    end

    test "for_country/1 works for all valid countries" do
      Enum.each(~w(ar cl co gt mx pe), fn country ->
        assert %Credential{} = Credential.for_country(country)
      end)
    end
  end
end
