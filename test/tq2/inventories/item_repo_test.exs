defmodule Tq2.Inventories.ItemRepoTest do
  use Tq2.DataCase

  describe "item" do
    alias Tq2.Accounts.{Account, Session}
    alias Tq2.Inventories
    alias Tq2.Inventories.Item

    @valid_attrs %{
      name: "some name",
      description: "some description",
      visibility: "visible",
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      account_id: "1"
    }

    def item_fixture(attrs \\ %{}) do
      account = Tq2.Repo.get_by!(Account, name: "test_account")
      session = %Session{account: account}

      item_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, item} = Inventories.create_item(session, item_attrs)

      item
    end

    test "converts unique constraint on name to error" do
      account = Tq2.Repo.get_by!(Account, name: "test_account")
      item = item_fixture(@valid_attrs)
      attrs = Map.put(@valid_attrs, :name, item.name)
      changeset = Item.changeset(account, %Item{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:name, :account_id]]
      }

      assert expected == changeset.errors[:name]
    end
  end
end
