defmodule Tq2Web.UserViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.UserView
  alias Tq2.Accounts
  alias Tq2.Accounts.User

  import Phoenix.View
  import Phoenix.HTML, only: [safe_to_string: 1]

  test "renders index.html", %{conn: conn} do
    page = %Scrivener.Page{total_pages: 1, page_number: 1}

    users = [
      %User{id: "1", name: "John", lastname: "Doe", email: "j@doe.com"},
      %User{id: "2", name: "Jane", lastname: "Doe", email: "jd@doe.com"}
    ]

    content = render_to_string(UserView, "index.html", conn: conn, users: users, page: page)

    for user <- users do
      assert String.contains?(content, user.name)
    end
  end

  test "renders new.html", %{conn: conn} do
    changeset = Accounts.change_user(%User{})
    content = render_to_string(UserView, "new.html", conn: conn, changeset: changeset)

    assert String.contains?(content, "New user")
  end

  test "renders edit.html", %{conn: conn} do
    user = user()

    changeset = Accounts.change_user(user)

    content =
      render_to_string(UserView, "edit.html",
        conn: conn,
        user: user,
        changeset: changeset
      )

    assert String.contains?(content, user.name)
  end

  test "renders show.html", %{conn: conn} do
    user = user()

    content = render_to_string(UserView, "show.html", conn: conn, user: user)

    assert String.contains?(content, user.name)
  end

  test "link to show", %{conn: conn} do
    user = user()

    content =
      conn
      |> UserView.link_to_show(user)
      |> safe_to_string()

    assert content =~ user.id
    assert content =~ "href"
  end

  test "link to edit", %{conn: conn} do
    user = user()

    content =
      conn
      |> UserView.link_to_edit(user)
      |> safe_to_string()

    assert content =~ user.id
    assert content =~ "href"
  end

  test "link to delete", %{conn: conn} do
    user = user()

    content =
      conn
      |> UserView.link_to_delete(user)
      |> safe_to_string()

    assert content =~ user.id
    assert content =~ "href"
    assert content =~ "delete"
  end

  defp user do
    %User{id: "1", name: "John", lastname: "Doe", email: "j@doe.com"}
  end
end
