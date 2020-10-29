defmodule Tq2Web.AccountViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.AccountView
  alias Tq2.Accounts
  alias Tq2.Accounts.Account

  import Phoenix.View
  import Phoenix.HTML, only: [safe_to_string: 1]

  test "renders index.html", %{conn: conn} do
    page = %Scrivener.Page{total_pages: 1, page_number: 1}

    accounts = [
      %Account{
        id: "1",
        name: "Google",
        status: "green",
        country: "ar",
        time_zone: "America/Argentina/Mendoza"
      },
      %Account{
        id: "2",
        name: "Amazon",
        status: "green",
        country: "ar",
        time_zone: "America/Argentina/Mendoza"
      }
    ]

    content =
      render_to_string(AccountView, "index.html", conn: conn, accounts: accounts, page: page)

    for account <- accounts do
      assert String.contains?(content, account.name)
    end
  end

  test "renders new.html", %{conn: conn} do
    changeset = Accounts.change_account(%Account{})
    content = render_to_string(AccountView, "new.html", conn: conn, changeset: changeset)

    assert String.contains?(content, "New account")
  end

  test "renders edit.html", %{conn: conn} do
    account = %Account{
      id: "1",
      name: "Google",
      status: "green",
      country: "ar",
      time_zone: "America/Argentina/Mendoza"
    }

    changeset = Accounts.change_account(account)

    content =
      render_to_string(AccountView, "edit.html",
        conn: conn,
        account: account,
        changeset: changeset
      )

    assert String.contains?(content, account.name)
  end

  test "renders show.html", %{conn: conn} do
    account = account()

    content = render_to_string(AccountView, "show.html", conn: conn, account: account)

    assert String.contains?(content, account.name)
  end

  test "link to show", %{conn: conn} do
    account = account()

    content =
      conn
      |> AccountView.link_to_show(account)
      |> safe_to_string()

    assert content =~ account.id
    assert content =~ "href"
  end

  test "link to edit", %{conn: conn} do
    account = account()

    content =
      conn
      |> AccountView.link_to_edit(account)
      |> safe_to_string()

    assert content =~ account.id
    assert content =~ "href"
  end

  test "link to delete", %{conn: conn} do
    account = account()

    content =
      conn
      |> AccountView.link_to_delete(account)
      |> safe_to_string()

    assert content =~ account.id
    assert content =~ "href"
    assert content =~ "delete"
  end

  test "status" do
    account = account()

    assert AccountView.status(account) =~ "Green"
  end

  test "country" do
    account = account()

    assert AccountView.country(account) =~ "Argentina"
  end

  test "statuses" do
    assert %{} = AccountView.statuses()
  end

  test "countries" do
    assert %{} = AccountView.countries()
  end

  test "time zones" do
    assert is_list(AccountView.time_zones())
  end

  defp account do
    %Account{
      id: "1",
      name: "Google",
      status: "green",
      country: "ar",
      time_zone: "America/Argentina/Mendoza"
    }
  end
end
