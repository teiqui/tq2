defmodule Tq2Web.AccountView do
  use Tq2Web, :view
  use Scrivener.HTML

  import Tq2.Utils.Urls, only: [store_uri: 0]
  import Tq2Web.Utils, only: [localize_date: 1]

  alias Tq2.Accounts.Account

  # Done so we avoid dngettext and we can get "merge" magic
  @countries %{
    dgettext("accounts", "Argentina") => "ar",
    dgettext("accounts", "Chile") => "cl",
    dgettext("accounts", "Colombia") => "co",
    dgettext("accounts", "Guatemala") => "gt",
    dgettext("accounts", "Mexico") => "mx",
    dgettext("accounts", "Peru") => "pe"
  }

  @statuses %{
    dgettext("accounts", "Green") => "green",
    dgettext("accounts", "Active") => "active",
    dgettext("accounts", "Suspended") => "suspended"
  }

  def link_to_show(conn, account) do
    icon_link(
      "eye-fill",
      title: dgettext("accounts", "Show"),
      to: Routes.account_path(conn, :show, account),
      class: "ml-2"
    )
  end

  def status(account) do
    statuses = invert(@statuses)

    statuses[account.status]
  end

  def country(account) do
    countries = invert(@countries)

    countries[account.country]
  end

  defp invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end

  defp filtered?(params) do
    params
    |> Enum.reject(fn {_, v} -> is_nil(v) || v == "" end)
    |> Enum.any?()
  end

  defp store_url(%Account{store: store}) do
    store_uri() |> Routes.counter_url(:index, store)
  end
end
