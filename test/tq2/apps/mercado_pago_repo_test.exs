defmodule Tq2.Apps.MercadoPagoRepoTest do
  use Tq2.DataCase

  describe "mercado_pago" do
    import Tq2.Fixtures, only: [app_mercado_pago_fixture: 0, default_account: 0]

    alias Tq2.Apps
    alias Tq2.Apps.MercadoPago

    @valid_attrs %{
      name: "mercado_pago",
      status: "active",
      data: %{access_token: "TEST-123-asd-123"}
    }

    test "converts unique constraint on name to error" do
      app_mercado_pago_fixture()

      changeset = Apps.change_app(default_account(), %MercadoPago{}, @valid_attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:name, :account_id]]
      }

      assert expected == changeset.errors[:name]
    end
  end
end
