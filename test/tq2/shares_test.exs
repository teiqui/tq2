defmodule Tq2.SharesTest do
  use Tq2.DataCase

  alias Tq2.Shares

  describe "tokens" do
    alias Tq2.Shares.Token

    @valid_attrs %{
      value: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
      customer_id: "1"
    }
    @update_attrs %{
      value: "i6hmbFG7reYoDfGfrt0K3lwLoKl3_37JjLCQzIO-FGk="
    }
    @invalid_attrs %{
      value: nil,
      customer_id: nil
    }
    defp fixture(:customer) do
      {:ok, customer} =
        Tq2.Sales.create_customer(%{
          name: "some name",
          email: "some@email.com",
          phone: "555-5555",
          address: "some address"
        })

      customer
    end

    defp fixture(:token, attrs \\ %{}) do
      customer = fixture(:customer)

      token_attrs =
        attrs
        |> Map.put(:customer_id, customer.id)
        |> Enum.into(@valid_attrs)

      {:ok, token} = Shares.create_token(token_attrs)

      token
    end

    test "get_token!/1 returns the token with given id" do
      token = fixture(:token)

      assert Shares.get_token!(token.value) == token
    end

    test "create_token/1 with valid data creates a token" do
      customer = fixture(:customer)

      assert {:ok, %Token{} = token} =
               Shares.create_token(%{@valid_attrs | customer_id: customer.id})

      assert token.value == @valid_attrs.value
    end

    test "create_token/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Shares.create_token(@invalid_attrs)
    end

    test "update_token/2 with valid data updates the token" do
      token = fixture(:token)

      assert {:ok, token} = Shares.update_token(token, @update_attrs)
      assert %Token{} = token
      assert token.value == @update_attrs.value
    end

    test "update_token/2 with invalid data returns error changeset" do
      token = fixture(:token)

      assert {:error, %Ecto.Changeset{}} = Shares.update_token(token, @invalid_attrs)
      assert token == Shares.get_token!(token.value)
    end

    test "delete_token/1 deletes the token" do
      token = fixture(:token)

      assert {:ok, %Token{}} = Shares.delete_token(token)
      assert_raise Ecto.NoResultsError, fn -> Shares.get_token!(token.value) end
    end

    test "change_token/1 returns a token changeset" do
      token = fixture(:token)

      assert %Ecto.Changeset{} = Shares.change_token(token)
    end
  end
end
