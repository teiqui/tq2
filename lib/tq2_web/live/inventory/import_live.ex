defmodule Tq2Web.Inventory.ImportLive do
  use Tq2Web, :live_view
  @impl true
  def mount(_, %{"account_id" => _, "user_id" => _}, socket) do
    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> put_flash(:error, dgettext("sessions", "You must be logged in."))
      |> redirect(to: Routes.root_path(socket, :index))

    {:ok, socket}
  end

  defp link_to_section(socket, caption, to: section) do
    path = Routes.import_path(socket, :show, section)

    content = ~E"""
      <%= caption %>

      <span class="h6 text-primary float-right mb-0">
        <i class="bi-chevron-right"></i>
      </span>
    """

    live_patch(content, to: path, class: "list-group-item list-group-item-action bg-light py-3")
  end
end
