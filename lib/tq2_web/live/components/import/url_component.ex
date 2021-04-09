defmodule Tq2Web.Import.UrlComponent do
  use Tq2Web, :live_component

  def put_component_assigns(socket) do
    socket |> assign(:sheet_id, nil)
  end

  @impl true
  def handle_event("read", %{"read" => %{"url" => url}}, socket) do
    parsed_sheet_id = url |> sheet_id_from_url()
    socket = socket |> read_sheet_titles(parsed_sheet_id)

    {:noreply, socket}
  end

  defp sheet_id_from_url(url) do
    Regex.run(
      ~r/docs\.google\.com\/spreadsheets\/d\/([a-zA-Z0-9-_]+)/,
      url,
      capture: :all_but_first
    )
  end

  defp read_sheet_titles(socket, nil) do
    socket |> put_flash(:error, dgettext("items", "Can't read spreadsheet"))
  end

  defp read_sheet_titles(socket, [sheet_id]) do
    self() |> send({:read_titles, sheet_id})

    socket
  end

  defp submit_import do
    enable_text = dgettext("items", "Read")
    disable_text = dgettext("items", "Reading...")

    submit(enable_text,
      class: "btn btn-lg btn-block btn-primary",
      phx_disable_with: disable_text
    )
  end
end
