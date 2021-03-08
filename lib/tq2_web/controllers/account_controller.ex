defmodule Tq2Web.AccountController do
  use Tq2Web, :controller

  alias Tq2.Accounts

  plug :authenticate
  plug :authorize, as: :admin

  def index(conn, params) do
    page =
      params
      |> parse_params()
      |> Accounts.list_accounts()

    render_index(conn, params, page)
  end

  def show(conn, %{"id" => id}) do
    account = Accounts.get_account!(id)
    owner = Accounts.get_account_owner!(account)
    stats = Accounts.get_account_stats(account)

    render(conn, "show.html", account: account, owner: owner, stats: stats)
  end

  defp render_index(conn, _params, %{total_entries: 0}), do: render(conn, "empty.html")

  defp render_index(conn, params, page) do
    render(conn, "index.html", accounts: page.entries, page: page, params: params)
  end

  defp parse_params(%{"name" => name} = params) do
    {_name, params} = Map.pop(params, "name")

    params
    |> parse_params()
    |> Map.merge(%{"name" => name})
  end

  defp parse_params(%{"inserted_from" => from, "inserted_to" => to}) do
    %{"inserted_from" => parse_date(from, :beginning), "inserted_to" => parse_date(to, :end)}
    |> Enum.filter(fn {_, v} -> v end)
    |> Enum.into(%{})
  end

  defp parse_params(params), do: params

  defp parse_date("", _time), do: nil

  defp parse_date(date, :beginning) do
    date
    |> parse_date()
    |> Timex.beginning_of_day()
  end

  defp parse_date(date, :end) do
    date
    |> parse_date()
    |> Timex.end_of_day()
  end

  defp parse_date(date) do
    Timex.parse!(date, "{YYYY}-{0M}-{D}")
  end
end
