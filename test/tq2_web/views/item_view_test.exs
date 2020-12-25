defmodule Tq2Web.ItemViewTest do
  use Tq2Web.ConnCase, async: true
  use Tq2.Support.LoginHelper

  alias Tq2Web.ItemView
  alias Tq2.Inventories
  alias Tq2.Inventories.{Category, Item}

  import Phoenix.View
  import Phoenix.HTML, only: [safe_to_string: 1]

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "renders index.html", %{conn: conn} do
    page = %Scrivener.Page{total_pages: 1, page_number: 1}

    items = [
      %Item{
        id: "1",
        sku: "123",
        name: "Chocolate",
        description: "Very good",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        account_id: "1",
        category_id: "1",
        category: %Category{
          id: "1",
          name: "Candy",
          ordinal: "0"
        }
      },
      %Item{
        id: "2",
        sku: "234",
        name: "Coke",
        description: "Amazing",
        visibility: "visible",
        price: Money.new(120, :ARS),
        promotional_price: Money.new(110, :ARS),
        cost: Money.new(100, :ARS),
        account_id: "1",
        category_id: "2",
        category: %Category{
          id: "2",
          name: "Drinks",
          ordinal: "0"
        }
      }
    ]

    content = render_to_string(ItemView, "index.html", conn: conn, items: items, page: page)

    for item <- items do
      assert String.contains?(content, item.name)
    end
  end

  @tag login_as: "test@user.com"
  test "renders new.html", %{conn: conn} do
    changeset = account() |> Inventories.change_item(%Item{})

    content =
      render_to_string(ItemView, "new.html",
        conn: conn,
        changeset: changeset,
        current_session: conn.assigns.current_session
      )

    assert String.contains?(content, "New item")
  end

  @tag login_as: "test@user.com"
  test "renders edit.html", %{conn: conn} do
    item = item()
    changeset = account() |> Inventories.change_item(item)

    content =
      render_to_string(ItemView, "edit.html",
        conn: conn,
        item: item,
        changeset: changeset,
        current_session: conn.assigns.current_session
      )

    assert String.contains?(content, item.name)
  end

  test "renders show.html", %{conn: conn} do
    item = item()

    content = render_to_string(ItemView, "show.html", conn: conn, item: item)

    assert String.contains?(content, item.name)
  end

  test "link to show", %{conn: conn} do
    item = item()

    content =
      conn
      |> ItemView.link_to_show(item)
      |> safe_to_string()

    assert content =~ item.id
    assert content =~ "href"
  end

  test "link to edit", %{conn: conn} do
    item = item()

    content =
      conn
      |> ItemView.link_to_edit(item)
      |> safe_to_string()

    assert content =~ item.id
    assert content =~ "href"
  end

  test "link to delete", %{conn: conn} do
    item = item()

    content =
      conn
      |> ItemView.link_to_delete(item)
      |> safe_to_string()

    assert content =~ item.id
    assert content =~ "href"
    assert content =~ "delete"
  end

  test "visibility" do
    item = item()

    assert ItemView.visibility(item) =~ "Visible"
  end

  test "category" do
    item = item()

    assert ItemView.category(item.category) =~ "Candy"
  end

  test "visibilities" do
    assert %{} = ItemView.visibilities()
  end

  test "categories" do
    assert [] = account() |> ItemView.categories()
  end

  test "money" do
    money = Money.new(100, :ARS)

    assert Money.to_string(money, symbol: true) == ItemView.money(money)
  end

  test "image" do
    item = item()

    content =
      item
      |> ItemView.image()
      |> safe_to_string()

    assert content =~ "<img"
    refute content =~ "<svg"
  end

  test "image placeholder" do
    content =
      %Item{}
      |> ItemView.image()
      |> safe_to_string()

    assert content =~ "<svg"
    refute content =~ "<img"
  end

  defp account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end

  defp item do
    %Item{
      id: "1",
      sku: "123",
      name: "Chocolate",
      description: "Very good",
      visibility: "visible",
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
      cost: Money.new(80, :ARS),
      image: "test.png",
      account_id: "1",
      category_id: "1",
      category: %Category{
        id: "1",
        name: "Candy",
        ordinal: "0"
      }
    }
  end
end
