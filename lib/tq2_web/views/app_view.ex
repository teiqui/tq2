defmodule Tq2Web.AppView do
  use Tq2Web, :view
  use Scrivener.HTML

  import Tq2Web.Utils, only: [invert: 1]

  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2.Apps.WireTransfer, as: WTApp

  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential

  @statuses %{
    dgettext("apps", "Active") => "active",
    dgettext("apps", "Paused") => "paused"
  }

  def link_to_edit(conn, app) do
    icon_link(
      conn,
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

  def app_names(%{country: country}) do
    [
      if(country in MPClient.countries(), do: "mercado_pago"),
      "wire_transfer"
    ]
    |> Enum.filter(& &1)
  end

  def app_by_name(apps, name) do
    Enum.find_value(apps, &if(&1.name == name, do: &1)) || build_app(name)
  end

  def build_app("mercado_pago") do
    %MPApp{}
  end

  def build_app("wire_transfer") do
    %WTApp{}
  end

  def build_app(_), do: nil

  def mp_link_to_commissions(conn, account) do
    url = MPClient.commission_url_for(account.country)

    icon_link(
      conn,
      "percent",
      text: dgettext("apps", "Commissions"),
      to: url,
      target: "_blank"
    )
  end

  def link_to_install(conn, app_name) do
    link(
      dgettext("apps", "Install"),
      to: Routes.app_path(conn, :new, name: app_name),
      class: "btn btn-primary rounded-pill font-weight-semi-bold mt-2"
    )
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, app) do
    hidden_input(form, :lock_version, value: app.lock_version)
  end

  def submit_button(nil) do
    submit(
      dgettext("apps", "Create"),
      class: "btn btn-primary rounded-pill font-weight-semi-bold"
    )
  end

  def submit_button(_) do
    submit(
      dgettext("apps", "Update"),
      class: "btn btn-primary rounded-pill font-weight-semi-bold"
    )
  end

  defp app_img_tag(conn, app_name) do
    img_tag(
      Routes.static_path(conn, "/images/#{app_name}.png"),
      alt: translate_app(app_name),
      width: "128",
      height: "128",
      class: "img-fluid rounded mr-3"
    )
  end

  defp translate_app("mercado_pago") do
    dgettext("apps", "MercadoPago")
  end

  defp translate_app("wire_transfer") do
    dgettext("apps", "Wire transfer")
  end

  defp instructions(%{country: country}, "mercado_pago") do
    link =
      link(
        dgettext("mercado_pago", "link"),
        to: MPCredential.credential_url(country),
        target: "_blank"
      )
      |> safe_to_string()

    content_tag(:p, class: "lead") do
      raw(
        dgettext(
          "mercado_pago",
          "To use MercadoPago you have to create an application following the next %{link} and then copy the production Access Token in the field below.",
          link: link
        )
      )
    end
  end

  defp instructions(_account, _), do: nil
end
