defmodule Tq2.InventoriesTest do
  use Tq2.DataCase

  alias Tq2.Inventories

  describe "categories" do
    setup [:create_session]

    alias Tq2.Inventories.Category

    @valid_attrs %{name: "some name", ordinal: 0}
    @update_attrs %{name: "some updated name", ordinal: 1}
    @invalid_attrs %{name: nil, ordinal: nil}

    defp create_session(_) do
      account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")

      {:ok, session: %Tq2.Accounts.Session{account: account}}
    end

    defp fixture(session, :category, attrs \\ %{}) do
      category_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, category} = Inventories.create_category(session, category_attrs)

      category
    end

    test "list_categories/2 returns all categories", %{session: session} do
      category = fixture(session, :category)

      assert Inventories.list_categories(session.account, %{}).entries == [category]
    end

    test "get_category!/2 returns the category with given id", %{session: session} do
      category = fixture(session, :category)

      assert Inventories.get_category!(session.account, category.id) == category
    end

    test "create_category/2 with valid data creates a category", %{session: session} do
      assert {:ok, %Category{} = category} = Inventories.create_category(session, @valid_attrs)
      assert category.name == @valid_attrs.name
      assert category.ordinal == @valid_attrs.ordinal
    end

    test "create_category/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = Inventories.create_category(session, @invalid_attrs)
    end

    test "update_category/3 with valid data updates the category", %{session: session} do
      category = fixture(session, :category)

      assert {:ok, category} = Inventories.update_category(session, category, @update_attrs)
      assert %Category{} = category
      assert category.name == @update_attrs.name
      assert category.ordinal == @update_attrs.ordinal
    end

    test "update_category/3 with invalid data returns error changeset", %{session: session} do
      category = fixture(session, :category)

      assert {:error, %Ecto.Changeset{}} =
               Inventories.update_category(session, category, @invalid_attrs)

      assert category == Inventories.get_category!(session.account, category.id)
    end

    test "delete_category/2 deletes the category", %{session: session} do
      category = fixture(session, :category)

      assert {:ok, %Category{}} = Inventories.delete_category(session, category)

      assert_raise Ecto.NoResultsError, fn ->
        Inventories.get_category!(session.account, category.id)
      end
    end

    test "change_category/2 returns a category changeset", %{session: session} do
      category = fixture(session, :category)

      assert %Ecto.Changeset{} = Inventories.change_category(session.account, category)
    end
  end
end
