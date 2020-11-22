defmodule Tq2.Shops.StoreRepoTest do
  use Tq2.DataCase

  describe "store" do
    alias Tq2.Accounts.{Account, Session}
    alias Tq2.Shops
    alias Tq2.Shops.Store

    @valid_attrs %{
      name: "some name",
      description: "some description",
      slug: "some_slug",
      published: true,
      account_id: "1"
    }

    def store_fixture(attrs \\ %{}) do
      account = Tq2.Repo.get_by!(Account, name: "test_account")
      session = %Session{account: account}

      store_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, store} = Shops.create_store(session, store_attrs)

      store
    end

    test "converts unique constraint on slug to error" do
      account = Tq2.Repo.get_by!(Account, name: "test_account")
      store = store_fixture(@valid_attrs)
      attrs = Map.put(@valid_attrs, :slug, store.slug)
      changeset = Store.changeset(account, %Store{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:slug]]
      }

      assert expected == changeset.errors[:slug]
    end
  end
end
