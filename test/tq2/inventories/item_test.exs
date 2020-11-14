defmodule Tq2.Inventories.ItemTest do
  use Tq2.DataCase, async: true

  describe "item" do
    alias Tq2.Inventories.Item

    @valid_attrs %{
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
      },
      account_id: "1"
    }
    @invalid_attrs %{
      sku: nil,
      name: nil,
      description: nil,
      visibility: nil,
      price: nil,
      promotional_price: nil,
      cost: nil,
      image: nil,
      account_id: nil
    }

    test "changeset with valid attributes" do
      changeset = default_account() |> Item.changeset(%Item{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> Item.changeset(%Item{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:sku, String.duplicate("a", 256))
        |> Map.put(:name, String.duplicate("a", 256))

      changeset = default_account() |> Item.changeset(%Item{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).sku
      assert "should be at most 255 character(s)" in errors_on(changeset).name
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:visibility, "xx")

      changeset = default_account() |> Item.changeset(%Item{}, attrs)

      assert "is invalid" in errors_on(changeset).visibility
    end

    test "changeset does not accept negative money attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:price, Money.new(-1, :ARS))
        |> Map.put(:promotional_price, Money.new(-1, :ARS))
        |> Map.put(:cost, Money.new(-1, :ARS))

      changeset = default_account() |> Item.changeset(%Item{}, attrs)

      assert "must be greater than or equal to 0" in errors_on(changeset).price
      assert "must be greater than or equal to 0" in errors_on(changeset).promotional_price
      assert "must be greater than or equal to 0" in errors_on(changeset).cost
    end

    test "changeset convert strings to money attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:price, "10")
        |> Map.put(:promotional_price, "20")
        |> Map.put(:cost, "30")

      changeset = default_account() |> Item.changeset(%Item{}, attrs)

      assert Money.parse("10", :ARS) == {:ok, changeset.changes.price}
      assert Money.parse("20", :ARS) == {:ok, changeset.changes.promotional_price}
      assert Money.parse("30", :ARS) == {:ok, changeset.changes.cost}
    end
  end

  defp default_account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end
