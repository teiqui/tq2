defmodule Tq2Web.Apps.MpMarketplaceController do
  use Tq2Web, :controller

  import Phoenix.HTML, only: [raw: 1]

  alias Tq2.Apps
  alias Tq2.Apps.MercadoPago, as: MPApp

  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential

  plug :authenticate

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def show(conn, params, session) do
    session.account
    |> Apps.get_app("mercado_pago")
    |> redirect_to_apps_or_process_params(conn, params, session)
  end

  defp redirect_to_apps_or_process_params(nil, conn, %{"code" => code}, session) do
    data =
      session.account.country
      |> MPCredential.for_country()
      |> MPClient.associate_marketplace(code)

    case Apps.create_app(session, %{name: "mercado_pago", data: data}) do
      {:ok, _} ->
        conn
        |> put_flash(:info, dgettext("mercado_pago", "Successfully authorized"))
        |> redirect(to: Routes.app_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        messages =
          changeset
          |> MPApp.full_messages()
          |> Enum.join("<br>")
          |> raw()

        conn
        |> put_flash(:error, messages)
        |> redirect(to: Routes.app_path(conn, :new, name: "mercado_pago"))
    end
  end

  defp redirect_to_apps_or_process_params(nil, conn, _, _) do
    conn
    |> put_flash(:error, dgettext("mercado_pago", "Invalid authorization"))
    |> redirect(to: Routes.app_path(conn, :new, name: "mercado_pago"))
  end

  defp redirect_to_apps_or_process_params(_, conn, _, _) do
    conn
    |> put_flash(:error, dgettext("mercado_pago", "Already authorized"))
    |> redirect(to: Routes.app_path(conn, :index))
  end
end
