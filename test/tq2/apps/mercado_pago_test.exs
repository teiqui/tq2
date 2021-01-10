defmodule Tq2.Apps.MercadoPagoTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [default_account: 0]
  import Tq2.Support.MercadoPagoHelper, only: [mock_check_credentials: 1]

  describe "mercado_pago" do
    alias Tq2.Apps.MercadoPago

    @valid_attrs %{
      "name" => "mercado_pago",
      "status" => "active",
      "data" => %{"access_token" => "TEST-123-asd-123"}
    }
    @invalid_attrs %{
      "status" => "unknown"
    }

    test "changeset with valid attributes" do
      mock_check_credentials do
        changeset = default_account() |> MercadoPago.changeset(%MercadoPago{}, @valid_attrs)

        assert changeset.valid?
      end
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> MercadoPago.changeset(%MercadoPago{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      changeset = default_account() |> MercadoPago.changeset(%MercadoPago{}, @invalid_attrs)

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset validate embed data" do
      attrs = @valid_attrs |> Map.put("data", %{})

      changeset = default_account() |> MercadoPago.changeset(%MercadoPago{}, attrs)

      refute changeset.valid?
      refute changeset.changes.data.valid?
      assert "can't be blank" in errors_on(changeset.changes.data).access_token
    end
  end
end
