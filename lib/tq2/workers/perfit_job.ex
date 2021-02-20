defmodule Tq2.Workers.PerfitJob do
  alias Tq2.Perfit

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, Session}

  def perform(deserialized_session) do
    deserialized_session
    |> convert_to_session()
    |> Perfit.create_contact()
  end

  defp convert_to_session(%{"user" => %{"email" => email}, "account" => account}) do
    user = Accounts.get_user(email: email)
    account = for {key, val} <- account, into: %{}, do: {String.to_atom(key), val}

    %Session{user: user, account: struct(Account, account)}
  end
end
