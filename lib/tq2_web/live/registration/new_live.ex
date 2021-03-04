defmodule Tq2Web.Registration.NewLive do
  use Tq2Web, :live_view

  import Tq2.Utils.Urls, only: [web_uri: 0]

  alias Tq2.Accounts
  alias Tq2.Accounts.Registration

  @impl true
  def mount(_params, %{"remote_ip" => ip, "campaign" => campaign}, socket) do
    changeset = %Registration{} |> Accounts.change_registration()

    socket =
      socket
      |> assign(changeset: changeset, campaign: campaign)
      |> assign_country(ip)

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  @impl true
  def handle_event(
        "save",
        %{"registration" => registration_params},
        %{assigns: %{campaign: campaign, country: country}} = socket
      ) do
    params =
      registration_params
      |> Map.put("country", country)
      |> Map.put("campaign", campaign)

    case Accounts.create_registration(params) do
      {:ok, %{registration: registration}} ->
        socket =
          socket
          |> redirect(to: Routes.registration_path(socket, :show, registration))

        {:noreply, socket}

      # Ecto.Multi error
      {:error, :registration, changeset, _changes} ->
        socket =
          socket
          |> assign(:changeset, changeset)

        {:noreply, socket}

      # Other Ecto.Multi error
      {:error, _other, _changeset, _changes} ->
        # TODO: handle this case properly
        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:changeset, changeset)

        {:noreply, socket}
    end
  end

  defp types do
    %{
      dgettext("registrations", "Butcher shop") => "butcher_shop",
      dgettext("registrations", "Grocery") => "grocery",
      dgettext("registrations", "Green grocery") => "green_grocery",
      dgettext("registrations", "Cleaning") => "cleaning",
      dgettext("registrations", "Deli") => "deli",
      dgettext("registrations", "Food / Restaurant") => "food",
      dgettext("registrations", "Bakery") => "bakery",
      dgettext("registrations", "Bookshop / Stationery") => "bookshop",
      dgettext("registrations", "Technology") => "technology",
      dgettext("registrations", "Other") => "other"
    }
  end

  defp submit_registration do
    submit(
      dgettext("registrations", "Create store"),
      class: "btn btn-lg btn-primary rounded-pill px-4 mt-4",
      phx_disable_with: dgettext("registrations", "Creating...")
    )
  end

  defp terms_of_service_link do
    safe_to_string(
      link(dgettext("registrations", "terms of service"),
        to: Routes.legal_url(web_uri(), :index),
        target: "_blank"
      )
    )
  end

  defp assign_country(socket, ip) do
    code =
      case Geolix.lookup(ip) do
        %{default: %{country: %{iso_code: code}}} -> String.downcase(code)
        _ -> "ar"
      end

    socket |> assign(country: code)
  end

  defp trial_days(%{campaign: "extended_trial"}), do: 30
  defp trial_days(_assigns), do: 14
end
