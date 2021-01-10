defmodule Tq2.Gateways.MercadoPago.CredentialTest do
  use Tq2.DataCase, async: true

  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2.Gateways.MercadoPago.Credential

  describe "mercado pago credentials" do
    test "for_app/1 returns Credential with token" do
      app = %MPApp{data: %{access_token: "3322"}}
      cred = Credential.for_app(app)

      assert cred.token == app.data.access_token
    end
  end
end
