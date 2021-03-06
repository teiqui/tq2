defmodule Tq2.Workers.PerfitJob do
  alias Tq2.Perfit

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, Session}

  def perform("create_contact", deserialized_session) do
    deserialized_session
    |> convert_to_session()
    |> Perfit.create_contact()
  end

  def perform("check_empty_items", deserialized_session) do
    deserialized_session
    |> convert_to_session()
    |> load_item_count()
    |> maybe_update_contact()
  end

  defp convert_to_session(%{"user" => %{"email" => email}, "account" => account}) do
    user = Accounts.get_user(email: email)
    account = for {key, val} <- account, into: %{}, do: {String.to_atom(key), val}

    %Session{user: user, account: struct(Account, account)}
  end

  defp load_item_count(%{account: account} = session) do
    {session, Tq2.Inventories.items_count(account)}
  end

  defp maybe_update_contact({session, 0}) do
    lists = Application.get_env(:tq2, :perfit)[:empty_items_lists]

    Perfit.update_contact(session, %{lists: lists})
  end

  defp maybe_update_contact({_session, _count}), do: nil
end
