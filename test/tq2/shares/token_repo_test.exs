defmodule Tq2.Shares.TokenRepoTest do
  use Tq2.DataCase

  describe "token" do
    alias Tq2.Shares
    alias Tq2.Shares.Token

    @valid_attrs %{
      value: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
      customer_id: nil
    }

    def token_fixture(attrs \\ %{}) do
      {:ok, customer} =
        Tq2.Sales.create_customer(%{
          name: "some name",
          email: "some@email.com",
          phone: "555-5555",
          address: "some address"
        })

      token_attrs = Enum.into(%{attrs | customer_id: customer.id}, @valid_attrs)

      {:ok, token} = Shares.create_token(token_attrs)

      token
    end

    test "converts unique constraint on value to error" do
      token = token_fixture(@valid_attrs)

      attrs =
        @valid_attrs
        |> Map.put(:value, token.value)
        |> Map.put(:customer_id, token.customer_id)

      {:error, changeset} = Token.changeset(%Token{}, attrs) |> Repo.insert()

      expected = {
        "has already been taken",
        [constraint: :unique, constraint_name: "tokens_value_index"]
      }

      assert expected == changeset.errors[:value]
    end
  end
end
