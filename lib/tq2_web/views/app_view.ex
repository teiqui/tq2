defmodule Tq2Web.AppView do
  use Tq2Web, :view
  use Scrivener.HTML

  import Utils, only: [invert: 1]

  alias Tq2.Apps.MercadoPago, as: MPApp

  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential

  @statuses %{
    dgettext("apps", "Active") => "active",
    dgettext("apps", "Paused") => "paused"
  }

  def link_to_edit(conn, app) do
    icon_link(
      "pencil",
      text: dgettext("apps", "Edit"),
      to: Routes.app_path(conn, :edit, app)
    )
  end

  def link_to_delete(conn, app) do
    link(
      dgettext("apps", "Delete"),
      to: Routes.app_path(conn, :delete, app),
      method: :delete,
      data: [confirm: dgettext("apps", "Are you sure?")],
      class: "text-danger"
    )
  end

  def statuses_collection do
    @statuses
  end

  def app_status(app) do
    text = invert(@statuses)[app.status]

    html_class =
      %{
        "active" => "success",
        "paused" => "warning"
      }[app.status]

    content_tag(:span, text, class: "badge badge-#{html_class}")
  end

  def app_names do
    ~w(mercado_pago)
  end

  def app_by_name(apps, name) do
    Enum.find_value(apps, &if(&1.name == name, do: &1)) || build_app(name)
  end

  def build_app("mercado_pago") do
    %MPApp{}
  end

  def build_app(_), do: nil

  def mp_link_to_authorize(account) do
    url =
      account.country
      |> MPCredential.for_country()
      |> MPClient.marketplace_association_link()

    link(
      dgettext("apps", "Link account"),
      to: url,
      class: "btn btn-primary"
    )
  end

  def mp_link_to_commissions(account) do
    url = MPClient.commission_url_for(account.country)

    icon_link(
      "percent",
      text: dgettext("apps", "Commissions"),
      to: url,
      target: "_blank"
    )
  end

  def mp_link_to_install(conn) do
    link(
      dgettext("apps", "Install"),
      to: Routes.app_path(conn, :new, name: "mercado_pago"),
      class: "btn btn-primary rounded-pill font-weight-semi-bold mt-2"
    )
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, app) do
    hidden_input(form, :lock_version, value: app.lock_version)
  end

  def submit_button do
    submit(
      dgettext("apps", "Update"),
      class: "btn btn-primary rounded-pill font-weight-semi-bold"
    )
  end
end
