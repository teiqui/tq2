defmodule Tq2.Webhooks.MercadoPagoTest do
  use Tq2.DataCase, async: true

  describe "webhooks" do
    alias Tq2.Webhooks.MercadoPago

    @valid_attrs %{
      name: "mercado_pago",
      payload: %{"user_id" => "123"}
    }

    @invalid_attrs %{
      name: nil,
      payload: nil
    }

    test "changeset with valid attributes" do
      changeset = MercadoPago.changeset(%MercadoPago{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = MercadoPago.changeset(%MercadoPago{}, @invalid_attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).payload
      assert "can't be blank" in errors_on(changeset).name
    end
  end
end
