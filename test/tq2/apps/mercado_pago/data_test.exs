defmodule Tq2.Apps.MercadoPago.DataTest do
  use Tq2.DataCase

  import Tq2.Fixtures,
    only: [
      app_mercado_pago_fixture: 0,
      default_account: 1
    ]

  import Tq2.Support.MercadoPagoHelper,
    only: [mock_check_credentials: 1, mock_check_credentials: 2]

  describe "mercado pago data" do
    alias Tq2.Accounts
    alias Tq2.Apps.MercadoPago.Data, as: MPData

    @valid_attrs %{
      access_token: "TEST-123-asd-123",
      user_id: ""
    }
    @invalid_attrs %{
      access_token: ""
    }

    setup [:default_account]

    test "changeset with valid attributes", %{account: account} do
      mock_check_credentials do
        changeset = %MPData{} |> MPData.changeset(@valid_attrs, account)

        assert changeset.valid?
      end
    end

    test "changeset with invalid attributes", %{account: account} do
      changeset = %MPData{} |> MPData.changeset(@invalid_attrs, account)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:access_token, String.duplicate("a", 101))

      changeset = %MPData{} |> MPData.changeset(attrs, account)

      assert "should be at most 100 character(s)" in errors_on(changeset).access_token
    end

    test "changeset validate token", %{account: account} do
      attrs = @valid_attrs |> Map.put(:access_token, "other-123-asd-123")

      changeset = %MPData{} |> MPData.changeset(attrs, account)

      assert "is invalid" in errors_on(changeset).access_token
    end

    test "changeset remote check token", %{account: account} do
      mock_check_credentials %{"message" => "invalid token"} do
        changeset = %MPData{} |> MPData.changeset(@valid_attrs, account)

        assert "Invalid credentials: 'invalid token'" in errors_on(changeset).access_token
      end
    end

    test "changeset validate user_id", %{account: account} do
      mock_check_credentials do
        changeset = %MPData{} |> MPData.changeset(@valid_attrs, account)

        assert changeset.valid?
        assert changeset.changes.user_id == "123"
      end
    end

    test "changeset validate unique user_id" do
      {:ok, other_account} =
        Accounts.create_account(%{
          country: "ar",
          name: "other",
          status: "active",
          time_zone: "America/Argentina/Mendoza"
        })

      app_mercado_pago_fixture()

      mock_check_credentials do
        changeset = %MPData{} |> MPData.changeset(@valid_attrs, other_account)

        assert "Can't link with a used MercadoPago account" in errors_on(changeset).access_token
      end
    end
  end
end
