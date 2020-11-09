defmodule Tq2.Inventories.CategoryRepoTest do
  use Tq2.DataCase

  describe "category" do
    alias Tq2.Accounts.{Account, Session}
    alias Tq2.Inventories
    alias Tq2.Inventories.Category

    @valid_attrs %{
      name: "some name",
      ordinal: "0"
    }

    def category_fixture(attrs \\ %{}) do
      account = Tq2.Repo.get_by!(Account, name: "test_account")
      session = %Session{account: account}

      category_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, category} = Inventories.create_category(session, category_attrs)

      category
    end

    test "converts unique constraint on name to error" do
      account = Tq2.Repo.get_by!(Account, name: "test_account")
      category = category_fixture(@valid_attrs)
      attrs = Map.put(@valid_attrs, :name, category.name)
      changeset = Category.changeset(account, %Category{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:name, :account_id]]
      }

      assert expected == changeset.errors[:name]
    end
  end
end
