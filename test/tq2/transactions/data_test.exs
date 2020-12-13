defmodule Tq2.Transactions.DataTest do
  use Tq2.DataCase, async: true

  describe "data" do
    alias Tq2.Transactions.Data

    @valid_attrs %{handing: "pickup"}
    @invalid_attrs %{handing: "wrong"}

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

      changeset = Data.changeset(%Data{}, attrs)

      assert "is invalid" in errors_on(changeset).handing
    end
  end
end
