defmodule Tq2.Shares.TokenTest do
  use Tq2.DataCase, async: true

  describe "token" do
    alias Tq2.Shares.Token

    @valid_attrs %{
      value: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c="
    }
    @invalid_attrs %{
      value: nil
    }

    test "changeset with valid attributes" do
      changeset = Token.changeset(%Token{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Token.changeset(%Token{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:value, String.duplicate("a", 256))

      changeset = Token.changeset(%Token{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).value
    end
  end
end
