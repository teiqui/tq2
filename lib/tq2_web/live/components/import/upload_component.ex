defmodule Tq2Web.Import.UploadComponent do
  use Tq2Web, :live_component

  @mime_types ~w(
    text/csv
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.oasis.opendocument.spreadsheet
  )

  def put_component_assigns(socket) do
    socket
    |> allow_upload(:file,
      accept: @mime_types,
      max_entries: 1,
      auto_upload: true,
      progress: &handle_upload/3
    )
  end

  @impl true
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  defp handle_upload(:file, entry, socket) do
    if entry.done? do
      consume_uploaded_entries(socket, :file, fn meta, entry ->
        path = "#{meta.path}-#{entry.client_name}"

        File.cp!(meta.path, path)

        self() |> send({:upload_file, path})
      end)
    end

    socket = socket |> assign(uploading: true)

    {:noreply, socket}
  end
end
