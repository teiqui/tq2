defmodule Tq2Web.AccountView do
  use Tq2Web, :view
  use Scrivener.HTML

  import Tq2.Utils.Urls, only: [store_uri: 0]
  import Tq2Web.Utils, only: [localize_date: 1, invert: 1]

  alias Tq2.Accounts.{Account, License}

  # Done so we avoid dngettext and we can get "merge" magic
  @countries %{
    dgettext("accounts", "Argentina") => "ar",
    dgettext("accounts", "Chile") => "cl",
    dgettext("accounts", "Colombia") => "co",
    dgettext("accounts", "Guatemala") => "gt",
    dgettext("accounts", "Mexico") => "mx",
    dgettext("accounts", "Peru") => "pe"
  }

  @license_statuses %{
    dgettext("licenses", "Trial") => "trial",
    dgettext("licenses", "Active") => "active",
    dgettext("licenses", "Unpaid") => "unpaid",
    dgettext("licenses", "Locked") => "locked",
    dgettext("licenses", "Canceled") => "canceled"
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

  def status(%Account{} = account) do
    statuses = invert(@statuses)

    statuses[account.status]
  end

  def status(%License{} = license) do
    statuses = invert(@license_statuses)

    statuses[license.status]
  end

  def country(account) do
    countries = invert(@countries)

    countries[account.country] || account.country
  end

  defp filtered?(params) do
    params
    |> Enum.reject(fn {_, v} -> is_nil(v) || v == "" end)
    |> Enum.any?()
  end

  defp store_url(%Account{store: store}) do
    store_uri() |> Routes.counter_url(:index, store)
  end

  defp store_email_link(%{data: %{email: email}}) when is_binary(email) do
    link(email, to: {:mailto, email})
  end

  defp store_email_link(_store), do: "-"

  defp store_phone(%{data: %{phone: phone}}) when is_binary(phone) do
    phone
  end

  defp store_phone(_store), do: "-"

  defp store_whatsapp(%{data: %{whatsapp: whatsapp}}) when is_binary(whatsapp) do
    whatsapp
  end

  defp store_whatsapp(_store), do: "-"

  defp link_to_extend_license(conn, account) do
    link(
      dgettext("accounts", "Extend trial period"),
      to: Routes.account_path(conn, :update, account, extend_license: true),
      method: :put,
      data: [confirm: dgettext("accounts", "Are you sure?")],
      class: "btn btn-sm btn-primary"
    )
  end
end
