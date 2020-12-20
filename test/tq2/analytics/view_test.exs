defmodule Tq2.Analytics.ViewTest do
  use Tq2.DataCase, async: true

  describe "view" do
    alias Tq2.Analytics.View

    @valid_attrs %{
      path: "/",
      visit_id: "1"
    }
    @invalid_attrs %{
      path: nil,
      visit_id: nil
    }

    test "changeset with valid attributes" do
      changeset = View.changeset(%View{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = View.changeset(%View{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:path, String.duplicate("a", 256))

      changeset = View.changeset(%View{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).path
    end
  end
end
