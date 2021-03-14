defmodule Tq2.Transactions.LineTest do
  use Tq2.DataCase, async: true

  alias Tq2.Transactions.{Cart, Line}

  describe "line" do
    @valid_attrs %{
      name: "some name",
      quantity: 1,
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      cart_id: "1",
      item: %Tq2.Inventories.Item{
        name: "some name",
        description: "some description",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        account_id: "1"
      }
    }
    @invalid_attrs %{
      name: nil,
      quantity: nil,
      price: nil,
      promotional_price: nil,
      cart_id: nil,
      item: nil
    }

    test "changeset with valid attributes" do
      item = @valid_attrs[:item]
      changeset = cart() |> Line.changeset(%Line{item: item}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = cart() |> Line.changeset(%Line{}, @invalid_attrs)

      refute changeset.valid?
    end
  end

  defp cart do
    %Cart{
      price_type: "promotional",
      account_id: "1"
    }
  end
end
