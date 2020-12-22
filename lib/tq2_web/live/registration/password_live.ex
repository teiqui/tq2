defmodule Tq2Web.Registration.PasswordLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts

  @impl true
  def mount(%{"uuid" => uuid}, _session, socket) do
    changeset =
      uuid
      |> Accounts.get_registration!()
      |> Accounts.change_registration()

    socket =
      socket
      |> assign(:changeset, changeset)

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  @impl true
  def handle_event("save", %{"registration" => %{"uuid" => uuid} = registration_params}, socket) do
    registration = Accounts.get_registration!(uuid)

    case Accounts.finish_registration(registration, registration_params) do
      {:ok, %{registration: registration}} ->
        socket =
          socket
          |> redirect(to: Routes.registration_path(socket, :show, registration))

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
      phx_disable_width: dgettext("registrations", "Creating...")
    )
  end
end
