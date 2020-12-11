defmodule Tq2.Apps.MercadoPagoRepoTest do
  use Tq2.DataCase, async: true

  describe "mercado_pago" do
    import Tq2.Fixtures, only: [create_session: 0]

    alias Tq2.Apps
    alias Tq2.Apps.MercadoPago

    @valid_attrs %{
      name: "mercado_pago",
      status: "active",
      data: %{"access_token" => "123-asd"}
    }

    test "converts unique constraint on name to error" do
      session = create_session()

      mercado_pago_fixture(session)

      changeset = Apps.change_app(session.account, %MercadoPago{}, @valid_attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:name, :account_id]]
      }

      assert expected == changeset.errors[:name]
    end

    defp mercado_pago_fixture(session) do
      {:ok, app} = Apps.create_app(session, @valid_attrs)

      app
    end
  end
end
