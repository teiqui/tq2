defmodule Tq2.Apps.WireTransfer.DataTest do
  use Tq2.DataCase, async: true

  describe "wire_transfer" do
    alias Tq2.Apps.WireTransfer.Data

    @valid_attrs %{
      description: "Pay me",
      account_number: "123-123"
    }
    @invalid_attrs %{}

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
        |> Map.put(:description, String.duplicate("a", 256))
        |> Map.put(:account_number, String.duplicate("a", 256))

      changeset = Data.changeset(%Data{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).description
      assert "should be at most 255 character(s)" in errors_on(changeset).account_number
    end

    test "changeset check requires" do
      changeset = Data.changeset(%Data{}, @invalid_attrs)

      assert "can't be blank" in errors_on(changeset).description
      assert "can't be blank" in errors_on(changeset).account_number
    end
  end
end
