defmodule Tq2Web.Registration.EmailLive do
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

    case Accounts.update_registration(registration, registration_params) do
      {:ok, registration} ->
        socket =
          socket
          |> push_redirect(to: Routes.registration_password_path(socket, :index, registration))

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
      dgettext("registrations", "Continue"),
      class: "btn btn-lg btn-outline-primary border border-primary rounded-pill px-4 mt-4",
      phx_disable_width: dgettext("customers", "Saving...")
    )
  end
end
