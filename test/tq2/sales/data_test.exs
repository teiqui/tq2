defmodule Tq2.Sales.DataTest do
  use Tq2.DataCase, async: true

  describe "data" do
    alias Tq2.Sales.Data

    @valid_attrs %{
      paid: true,
      notes: "some notes"
    }

    test "changeset with valid attributes" do
      changeset = Data.changeset(%Data{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:notes, String.duplicate("a", 512))

      changeset = Data.changeset(%Data{}, attrs)

      assert "should be at most 511 character(s)" in errors_on(changeset).notes
    end
  end
end
