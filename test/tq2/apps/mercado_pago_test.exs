defmodule Tq2.Apps.MercadoPagoTest do
  use Tq2.DataCase, async: true

  describe "mercado_pago" do
    alias Tq2.Accounts
    alias Tq2.Accounts.Account
    alias Tq2.Apps.MercadoPago

    @valid_attrs %{
      name: "mercado_pago",
      status: "active",
      data: %{"access_token" => "123-asd"}
    }
    @invalid_attrs %{
      status: "unknown",
      data: %{"access_token" => ""}
    }

    test "changeset with valid attributes" do
      changeset = default_account() |> MercadoPago.changeset(%MercadoPago{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> MercadoPago.changeset(%MercadoPago{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      attrs = @valid_attrs |> Map.put(:status, "xx")

      changeset = default_account() |> MercadoPago.changeset(%MercadoPago{}, attrs)

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset validate token" do
      changeset = default_account() |> MercadoPago.changeset(%MercadoPago{}, @invalid_attrs)

      assert "Invalid MercadoPago token" in errors_on(changeset).data
    end

    test "changeset validate token with saved token" do
      attrs = @valid_attrs |> Map.delete(:data)
      mp_struct = %MercadoPago{id: 1, data: %{"access_token" => "asd-123"}}

      changeset = default_account() |> MercadoPago.changeset(mp_struct, attrs)

      assert changeset.valid?
    end

    test "changeset validate token with saved token and empty data" do
      attrs = @valid_attrs |> Map.put(:data, %{})
      mp_struct = %MercadoPago{id: 1, data: %{"access_token" => "asd-123"}}

      changeset = default_account() |> MercadoPago.changeset(mp_struct, attrs)

      refute changeset.valid?
    end

    test "changeset validates user_id uniqueness" do
      attrs = @valid_attrs |> Map.put(:data, %{"access_token" => "123-asd", "user_id" => "123"})

      {:ok, _app} =
        default_account()
        |> MercadoPago.changeset(%MercadoPago{}, attrs)
        |> Tq2.Repo.insert()

      {:ok, other_account} =
        Accounts.create_account(%{
          country: "ar",
          name: "other account",
          status: "active",
          time_zone: "America/Argentina/Mendoza"
        })

      changeset = other_account |> MercadoPago.changeset(%MercadoPago{}, attrs)

      refute changeset.valid?
      assert "Can't link with a used MercadoPago account" in errors_on(changeset).data
    end

    test "full_messages returns translated errors" do
      errors =
        default_account()
        |> MercadoPago.changeset(%MercadoPago{}, @invalid_attrs)
        |> MercadoPago.full_messages()

      assert "Invalid MercadoPago token" in errors
      assert "Status is invalid" in errors
    end

    defp default_account do
      Account
      |> where(name: "test_account")
      |> Tq2.Repo.one()
    end
  end
end
