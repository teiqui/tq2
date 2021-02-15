defmodule Tq2Web.AccountViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2Web.AccountView
  alias Tq2.Accounts.Account

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
    page = %Scrivener.Page{total_pages: 1, page_number: 1, total_entries: 1}

    accounts = [
      %Account{
        id: "1",
        name: "Google",
        status: "green",
        country: "ar",
        time_zone: "America/Argentina/Mendoza",
        inserted_at: DateTime.utc_now()
      },
      %Account{
        id: "2",
        name: "Amazon",
        status: "green",
        country: "ar",
        time_zone: "America/Argentina/Mendoza",
        inserted_at: DateTime.utc_now()
      }
    ]

    content =
      render_to_string(AccountView, "index.html",
        conn: conn,
        accounts: accounts,
        page: page,
        params: %{}
      )

    for account <- accounts do
      assert String.contains?(content, account.name)
    end
  end

  test "renders show.html", %{conn: conn} do
    account = account()
    stats = [orders_count: 0, carts_count: 0]

    content =
      render_to_string(AccountView, "show.html", conn: conn, account: account, stats: stats)

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

  test "status" do
    account = account()

    assert AccountView.status(account) =~ "Green"
  end

  test "country" do
    account = account()

    assert AccountView.country(account) =~ "Argentina"
  end

  defp account do
    %Account{
      id: "1",
      name: "Google",
      status: "green",
      country: "ar",
      time_zone: "America/Argentina/Mendoza",
      store: %Tq2.Shops.Store{
        name: "some name",
        description: "some description",
        slug: "other_slug",
        published: true
      }
    }
  end
end
