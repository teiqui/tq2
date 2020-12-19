defmodule Tq2.Analytics.DataTest do
  use Tq2.DataCase, async: true

  describe "data" do
    alias Tq2.Analytics.Data

    @valid_attrs %{
      ip: "127.0.0.1"
    }

    test "changeset with valid attributes" do
      changeset = Data.changeset(%Data{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:ip, String.duplicate("a", 256))

      changeset = Data.changeset(%Data{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).ip
    end
  end
end
