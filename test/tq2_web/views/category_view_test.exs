defmodule Tq2Web.CategoryViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.CategoryView
  alias Tq2.Inventories
  alias Tq2.Inventories.Category

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

    categories = [
      %Category{id: "1", name: "Food", ordinal: "0"},
      %Category{id: "2", name: "Drinks", ordinal: "1"}
    ]

    content =
      render_to_string(CategoryView, "index.html", conn: conn, categories: categories, page: page)

    for category <- categories do
      assert String.contains?(content, category.name)
    end
  end

  test "renders new.html", %{conn: conn} do
    changeset = account() |> Inventories.change_category(%Category{})
    content = render_to_string(CategoryView, "new.html", conn: conn, changeset: changeset)

    assert String.contains?(content, "New category")
  end

  test "renders edit.html", %{conn: conn} do
    category = category()
    changeset = account() |> Inventories.change_category(category)

    content =
      render_to_string(CategoryView, "edit.html",
        conn: conn,
        category: category,
        changeset: changeset
      )

    assert String.contains?(content, category.name)
  end

  test "renders show.html", %{conn: conn} do
    category = category()

    content = render_to_string(CategoryView, "show.html", conn: conn, category: category)

    assert String.contains?(content, category.name)
  end

  test "link to show", %{conn: conn} do
    category = category()

    content =
      conn
      |> CategoryView.link_to_show(category)
      |> safe_to_string()

    assert content =~ category.id
    assert content =~ "href"
  end

  test "link to edit", %{conn: conn} do
    category = category()

    content =
      conn
      |> CategoryView.link_to_edit(category)
      |> safe_to_string()

    assert content =~ category.id
    assert content =~ "href"
  end

  test "link to delete", %{conn: conn} do
    category = category()

    content =
      conn
      |> CategoryView.link_to_delete(category)
      |> safe_to_string()

    assert content =~ category.id
    assert content =~ "href"
    assert content =~ "delete"
  end

  defp account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end

  defp category do
    %Category{id: "1", name: "Food", ordinal: "0"}
  end
end
