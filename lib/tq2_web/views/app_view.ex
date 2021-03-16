defmodule Tq2Web.AppView do
  use Tq2Web, :view
  use Scrivener.HTML

  import Tq2Web.Utils, only: [invert: 1]

  alias Tq2.Apps.Conekta, as: CktApp
  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2.Apps.Transbank, as: TbkApp
  alias Tq2.Apps.WireTransfer, as: WTApp

  alias Tq2.Gateways.Conekta, as: CktClient
  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Gateways.Transbank, as: TbkClient

  @app_names ~w(conekta mercado_pago transbank wire_transfer)
  @app_modules %{
    "conekta" => CktApp,
    "mercado_pago" => MPApp,
    "transbank" => TbkApp,
    "wire_transfer" => WTApp
  }
  @client_modules %{
    "conekta" => CktClient,
    "mercado_pago" => MPClient,
    "transbank" => TbkClient
  }

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

  def app_names(%{country: country}) do
    [
      if(country in CktClient.countries(), do: "conekta"),
      if(country in MPClient.countries(), do: "mercado_pago"),
      if(country in TbkClient.countries(), do: "transbank"),
      "wire_transfer"
    ]
    |> Enum.filter(& &1)
  end

  def app_by_name(apps, name) do
    Enum.find_value(apps, &if(&1.name == name, do: &1)) || build_app(name)
  end

  def build_app(name) when name in @app_names, do: @app_modules[name].__struct__

  def build_app(_), do: nil

  def link_to_commissions(account, "mercado_pago") do
    url = MPClient.commission_url_for(account.country)

    icon_link(
      "percent",
      text: dgettext("apps", "Commissions"),
      to: url,
      target: "_blank"
    )
  end

  def link_to_commissions(_account, name) when name in ~w[conekta transbank] do
    url = @client_modules[name].commission_url()

    icon_link(
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

  defp translate_app("conekta") do
    dgettext("apps", "Conekta")
  end

  defp translate_app("mercado_pago") do
    dgettext("apps", "MercadoPago")
  end

  defp translate_app("transbank") do
    dgettext("apps", "Transbank - Onepay")
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

  defp instructions(_account, "conekta") do
    content_tag(:p, class: "lead mt-4 mx-4") do
      [
        conekta_sign_up_text(),
        conekta_api_key_text(),
        conekta_guide_text()
      ]
      |> Enum.join("<br>")
      |> raw()
    end
  end

  defp instructions(_account, _), do: nil

  defp conekta_sign_up_text do
    sign_up_link =
      "conekta"
      |> dgettext("sign up")
      |> link(
        to: "https://auth.conekta.com/sign_up",
        target: "_blank",
        class: "font-weight-semi-bold"
      )
      |> safe_to_string()

    "conekta"
    |> dgettext(
      "To link Conekta you should %{sign_up} in the platform.",
      sign_up: sign_up_link
    )
  end

  defp conekta_api_key_text do
    "conekta"
    |> dgettext(
      "Then go to Setting => API Keys and copy the Production API Key (private key) in the next field."
    )
  end

  defp conekta_guide_text do
    tutorial =
      "conekta"
      |> dgettext("tutorial")
      |> link(to: "#", data: [toggle: "modal", target: "#youtube_tutorial"])
      |> safe_to_string()

    "conekta" |> dgettext("You can also see our %{tutorial}.", tutorial: tutorial)
  end
end
