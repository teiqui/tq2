defmodule Tq2.Shops.LocationTest do
  use Tq2.DataCase, async: true

  describe "location" do
    alias Tq2.Shops.Location

    @valid_attrs %{
      latitude: "12",
      longitude: "123"
    }
    @invalid_attrs %{
      latitude: "800",
      longitude: "900"
    }

    test "changeset with valid attributes" do
      changeset = Location.changeset(%Location{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Location.changeset(%Location{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept number attributes out of range" do
      attrs =
        @valid_attrs
        |> Map.put(:latitude, -181)
        |> Map.put(:longitude, -181)

      changeset = Location.changeset(%Location{}, attrs)

      assert "must be greater than or equal to -180" in errors_on(changeset).latitude
      assert "must be greater than or equal to -180" in errors_on(changeset).longitude

      attrs =
        @valid_attrs
        |> Map.put(:latitude, 181)
        |> Map.put(:longitude, 181)

      changeset = Location.changeset(%Location{}, attrs)

      assert "must be less than or equal to 180" in errors_on(changeset).latitude
      assert "must be less than or equal to 180" in errors_on(changeset).longitude
    end
  end
end
