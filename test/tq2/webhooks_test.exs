defmodule Tq2.WebhooksTest do
  use Tq2.DataCase, async: true

  alias Tq2.Webhooks

  describe "mercado pago" do
    alias Tq2.Webhooks.MercadoPago

    @valid_attrs %{name: "mercado_pago", payload: %{"user_id" => "123"}}

    defp mercado_pago_fixture(attrs \\ %{}) do
      {:ok, mercado_pago} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Webhooks.create_webhook()

      mercado_pago
    end

    test "get_webhook/2 returns the mercado_pago with given id" do
      mercado_pago = mercado_pago_fixture()

      assert Webhooks.get_webhook("mercado_pago", mercado_pago.id) == mercado_pago
    end

    test "create_webhook/1 with valid data creates a mercado_pago" do
      assert {:ok, %MercadoPago{} = mercado_pago} = Webhooks.create_webhook(@valid_attrs)

      assert mercado_pago.name == @valid_attrs.name
      assert mercado_pago.payload == @valid_attrs.payload
    end

    test "create_webhook/1 with invalid data returns error changeset" do
      assert_raise RuntimeError, "Invalid webhook", fn ->
        Webhooks.create_webhook(%{payload: nil})
      end
    end
  end
end
