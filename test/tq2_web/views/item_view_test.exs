defmodule Tq2Web.ItemViewTest do
  use Tq2Web.ConnCase, async: true
  use Tq2.Support.LoginHelper

  alias Tq2Web.ItemView
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
        name: "Chocolate",
        description: "Very good",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
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
        name: "Coke",
        description: "Amazing",
        visibility: "visible",
        price: Money.new(120, :ARS),
        promotional_price: Money.new(110, :ARS),
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

  defp item do
    %Item{
      id: "1",
      name: "Chocolate",
      description: "Very good",
      visibility: "visible",
      price: Money.new(100, :ARS),
      promotional_price: Money.new(90, :ARS),
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
