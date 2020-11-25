defmodule Tq2.InventoriesTest do
  use Tq2.DataCase

  alias Tq2.Inventories

  @valid_category_attrs %{name: "some name", ordinal: 0}
  @update_category_attrs %{name: "some updated name", ordinal: 1}
  @invalid_category_attrs %{name: nil, ordinal: nil}

  @valid_item_attrs %{
    sku: "some sku",
    name: "some name",
    description: "some description",
    visibility: "visible",
    price: Money.new(100, :ARS),
    promotional_price: Money.new(90, :ARS),
    cost: Money.new(80, :ARS),
    image: %Plug.Upload{
      content_type: "image/png",
      filename: "test.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    }
  }
  @update_item_attrs %{
    sku: "some updated sku",
    name: "some updated name",
    description: "some updated description",
    visibility: "hidden",
    price: Money.new(110, :ARS),
    promotional_price: Money.new(100, :ARS),
    cost: Money.new(90, :ARS),
    image: nil
  }
  @invalid_item_attrs %{
    sku: nil,
    name: nil,
    description: nil,
    visibility: nil,
    price: nil,
    promotional_price: nil,
    cost: nil,
    image: nil
  }

  defp create_session(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")

    {:ok, session: %Tq2.Accounts.Session{account: account}}
  end

  defp fixture(session, schema, attrs \\ %{})

  defp fixture(session, :item, attrs) do
    item_attrs = Enum.into(attrs, @valid_item_attrs)

    {:ok, item} = Inventories.create_item(session, item_attrs)

    %{item | category: nil}
  end

  defp fixture(session, :category, attrs) do
    category_attrs = Enum.into(attrs, @valid_category_attrs)

    {:ok, category} = Inventories.create_category(session, category_attrs)

    category
  end

  describe "categories" do
    setup [:create_session]

    alias Tq2.Inventories.Category

    test "list_categories/1 returns all categories", %{session: session} do
      category = fixture(session, :category)

      assert Enum.map(Inventories.list_categories(session.account), & &1.id) == [category.id]
    end

    test "list_categories/2 returns all categories", %{session: session} do
      category = fixture(session, :category)

      assert Enum.map(Inventories.list_categories(session.account, %{}).entries, & &1.id) == [
               category.id
             ]
    end

    test "get_category!/2 returns the category with given id", %{session: session} do
      category = fixture(session, :category)

      assert Inventories.get_category!(session.account, category.id) == category
    end

    test "create_category/2 with valid data creates a category", %{session: session} do
      assert {:ok, %Category{} = category} =
               Inventories.create_category(session, @valid_category_attrs)

      assert category.name == @valid_category_attrs.name
      assert category.ordinal == @valid_category_attrs.ordinal
    end

    test "create_category/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} =
               Inventories.create_category(session, @invalid_category_attrs)
    end

    test "update_category/3 with valid data updates the category", %{session: session} do
      category = fixture(session, :category)

      assert {:ok, category} =
               Inventories.update_category(session, category, @update_category_attrs)

      assert %Category{} = category
      assert category.name == @update_category_attrs.name
      assert category.ordinal == @update_category_attrs.ordinal
    end

    test "update_category/3 with invalid data returns error changeset", %{session: session} do
      category = fixture(session, :category)

      assert {:error, %Ecto.Changeset{}} =
               Inventories.update_category(session, category, @invalid_category_attrs)

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

  describe "items" do
    setup [:create_session]

    alias Tq2.Inventories.Item

    test "list_items/2 returns all items", %{session: session} do
      item = fixture(session, :item)

      assert Inventories.list_items(session.account, %{}).entries == [item]
    end

    test "list_visible_items/2 returns all visible items", %{session: session} do
      item = fixture(session, :item)

      fixture(session, :item, %{name: "another name", sku: "another sku", visibility: "hidden"})

      assert Inventories.list_visible_items(session.account, %{}).entries == [item]
    end

    test "get_item!/2 returns the item with given id", %{session: session} do
      item = fixture(session, :item)

      assert Inventories.get_item!(session.account, item.id) == item
    end

    test "create_item/2 with valid data creates a item", %{session: session} do
      assert {:ok, %Item{} = item} = Inventories.create_item(session, @valid_item_attrs)
      assert item.sku == @valid_item_attrs.sku
      assert item.name == @valid_item_attrs.name
      assert item.description == @valid_item_attrs.description
      assert item.price == @valid_item_attrs.price
      assert item.promotional_price == @valid_item_attrs.promotional_price
      assert item.cost == @valid_item_attrs.cost
      assert item.visibility == @valid_item_attrs.visibility

      url =
        {item.image, item}
        |> Tq2.ImageUploader.url(:original)
        |> String.replace(~r(\?.*), "")

      path = Path.absname("priv/waffle/private#{url}")

      assert File.exists?(path)
    end

    test "create_item/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = Inventories.create_item(session, @invalid_item_attrs)
    end

    test "update_item/3 with valid data updates the item", %{session: session} do
      item = fixture(session, :item)

      assert {:ok, item} = Inventories.update_item(session, item, @update_item_attrs)
      assert %Item{} = item
      assert item.sku == @update_item_attrs.sku
      assert item.name == @update_item_attrs.name
      assert item.description == @update_item_attrs.description
      assert item.price == @update_item_attrs.price
      assert item.promotional_price == @update_item_attrs.promotional_price
      assert item.cost == @update_item_attrs.cost
      assert item.visibility == @update_item_attrs.visibility
    end

    test "update_item/3 with invalid data returns error changeset", %{session: session} do
      item = fixture(session, :item)

      assert {:error, %Ecto.Changeset{}} =
               Inventories.update_item(session, item, @invalid_item_attrs)

      assert item == Inventories.get_item!(session.account, item.id)
    end

    test "delete_item/2 deletes the item", %{session: session} do
      item = fixture(session, :item)

      assert {:ok, %Item{}} = Inventories.delete_item(session, item)
      assert_raise Ecto.NoResultsError, fn -> Inventories.get_item!(session.account, item.id) end
    end

    test "delete_item/2 deletes the item and his image", %{session: session} do
      item =
        fixture(session, :item, %{
          image: %Plug.Upload{
            content_type: "image/png",
            filename: "test_updated.png",
            path: Path.absname("test/support/fixtures/files/test.png")
          }
        })

      url =
        {item.image, item}
        |> Tq2.ImageUploader.url(:original)
        |> String.replace(~r(\?.*), "")

      path = Path.absname("priv/waffle/private#{url}")

      assert File.exists?(path)
      assert {:ok, %Item{}} = Inventories.delete_item(session, item)
      assert_raise Ecto.NoResultsError, fn -> Inventories.get_item!(session.account, item.id) end
      refute File.exists?(path)
    end

    test "change_item/2 returns a item changeset", %{session: session} do
      item = fixture(session, :item)

      assert %Ecto.Changeset{} = Inventories.change_item(session.account, item)
    end
  end
end
