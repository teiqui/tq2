defmodule Tq2Web.Import.PredefinedComponent do
  use Tq2Web, :live_component

  def put_component_assigns(%{assigns: %{grid_titles: [_ | _]}} = socket), do: socket

  def put_component_assigns(socket) do
    socket |> assign(grid_titles: grid_titles())
  end

  @impl true
  def handle_event("import", %{"import" => %{"grid_title" => title}}, socket) do
    opts = %{
      grid_title: title,
      sheet_id: default_sheet_id()
    }

    send(self(), {:import, opts})

    {:noreply, socket}
  end

  defp default_sheet_id do
    :tq2 |> Application.get_env(:default_sheet_id)
  end

  defp submit_import do
    enable_text = dgettext("items", "Import")
    disable_text = dgettext("items", "Importing...")

    submit(enable_text,
      class: "btn btn-lg btn-block btn-primary",
      phx_disable_with: disable_text
    )
  end

  defp grid_titles do
    default_sheet_id()
    |> Tq2.Gdrive.grid_titles()
    |> Enum.sort()
  end

  defp grid_title_prompt do
    dgettext("items", "Select store type...")
  end
end
