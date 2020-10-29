defmodule Tq2Web.AccountView do
  use Tq2Web, :view
  use Scrivener.HTML

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

  def link_to_edit(conn, account) do
    icon_link(
      "pencil-fill",
      title: dgettext("accounts", "Edit"),
      to: Routes.account_path(conn, :edit, account),
      class: "ml-2"
    )
  end

  def link_to_delete(conn, account) do
    icon_link(
      "trash2-fill",
      title: dgettext("accounts", "Delete"),
      to: Routes.account_path(conn, :delete, account),
      method: :delete,
      data: [confirm: dgettext("accounts", "Are you sure?")],
      class: "ml-2 text-danger"
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

  def statuses do
    @statuses
  end

  def countries do
    @countries
  end

  def time_zones do
    Tzdata.zone_lists_grouped()[:southamerica]
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, account) do
    hidden_input(form, :lock_version, value: account.lock_version)
  end

  def submit_button(account) do
    account
    |> submit_label()
    |> submit(class: "btn btn-primary")
  end

  defp submit_label(nil), do: dgettext("accounts", "Create")
  defp submit_label(_), do: dgettext("accounts", "Update")

  defp invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end
end
