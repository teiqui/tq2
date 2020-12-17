defmodule Tq2.Transactions.DataTest do
  use Tq2.DataCase, async: true

  describe "data" do
    alias Tq2.Transactions.Data

    @valid_attrs %{
      handing: "pickup",
      payment: "cash"
    }
    @invalid_attrs %{
      handing: "wrong",
      payment: "wrong"
    }

    test "changeset with valid attributes" do
      changeset = Data.changeset(%Data{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Data.changeset(%Data{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:handing, "xx")
        |> Map.put(:payment, "xx")

      changeset = Data.changeset(%Data{}, attrs)

      assert "is invalid" in errors_on(changeset).handing
      assert "is invalid" in errors_on(changeset).payment
    end
  end
end
