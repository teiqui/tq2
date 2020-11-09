defmodule Tq2.Inventories.CategoryTest do
  use Tq2.DataCase, async: true

  describe "category" do
    alias Tq2.Inventories.Category

    @valid_attrs %{
      name: "some name",
      ordinal: "0",
      account_id: "1"
    }
    @invalid_attrs %{
      name: nil,
      ordinal: nil,
      account_id: nil
    }

    test "changeset with valid attributes" do
      changeset = default_account() |> Category.changeset(%Category{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> Category.changeset(%Category{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:name, String.duplicate("a", 256))

      changeset = default_account() |> Category.changeset(%Category{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).name
    end

    test "changeset does not accept number attributes out of range" do
      account = default_account()
      attrs = @valid_attrs |> Map.put(:ordinal, -1)

      changeset = account |> Category.changeset(%Category{}, attrs)

      assert "must be greater than or equal to 0" in errors_on(changeset).ordinal

      attrs = @valid_attrs |> Map.put(:ordinal, 2_147_483_648)

      changeset = account |> Category.changeset(%Category{}, attrs)

      assert "must be less than 2147483648" in errors_on(changeset).ordinal
    end
  end

  defp default_account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end
