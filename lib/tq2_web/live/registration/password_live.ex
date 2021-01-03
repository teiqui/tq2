defmodule Tq2Web.Registration.PasswordLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts

  @impl true
  def mount(%{"uuid" => uuid}, %{"remote_ip" => ip}, socket) do
    changeset =
      uuid
      |> Accounts.get_registration!()
      |> Accounts.change_registration()

    socket =
      socket
      |> assign(changeset: changeset)
      |> assign_country(ip)

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  @impl true
  def handle_event(
        "save",
        %{"registration" => %{"uuid" => uuid} = registration_params},
        %{assigns: %{country: country}} = socket
      ) do
    registration = Accounts.get_registration!(uuid)
    params = registration_params |> Map.put("country", country)

    case Accounts.finish_registration(registration, params) do
      {:ok, %{registration: registration}} ->
        socket =
          socket
          |> redirect(to: Routes.registration_path(socket, :show, registration))

        {:noreply, socket}

      # Ecto.Multi error
      {:error, _operation, changeset, _changes} ->
        socket =
          socket
          |> assign(:changeset, changeset)

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:changeset, changeset)

        {:noreply, socket}
    end
  end

  defp submit_registration do
    submit(
      dgettext("registrations", "Create"),
      class: "btn btn-lg btn-primary rounded-pill px-4 mt-4",
      phx_disable_with: dgettext("registrations", "Creating...")
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
end
