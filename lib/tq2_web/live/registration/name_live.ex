defmodule Tq2Web.Registration.NameLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts
  alias Tq2.Accounts.Registration

  @impl true
  def mount(_params, _session, socket) do
    changeset = %Registration{} |> Accounts.change_registration()

    socket =
      socket
      |> assign(:changeset, changeset)

    {:ok, socket, temporary_assigns: [changeset: nil]}
  end

  @impl true
  def handle_event("save", %{"registration" => registration_params}, socket) do
    case Accounts.create_registration(registration_params) do
      {:ok, registration} ->
        socket =
          socket
          |> push_redirect(to: Routes.registration_email_path(socket, :index, registration))

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
      dgettext("registrations", "Continue"),
      class: "btn btn-lg btn-outline-primary border border-primary rounded-pill px-4 mt-4",
      phx_disable_width: dgettext("customers", "Saving...")
    )
  end
end
