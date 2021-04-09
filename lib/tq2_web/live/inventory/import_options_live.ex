defmodule Tq2Web.Inventory.ImportOptionsLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts
  alias Tq2.Inventories
  alias Tq2.Inventories.ItemImport

  alias Tq2Web.Import.{HeadersComponent, PredefinedComponent, UploadComponent, UrlComponent}

  @section_components %{
    "headers" => HeadersComponent,
    "predefined" => PredefinedComponent,
    "upload" => UploadComponent,
    "url" => UrlComponent
  }

  @impl true
  def mount(%{"section" => section}, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)

    if connected?(socket), do: Inventories.subscribe(session)

    socket =
      socket
      |> assign(
        section: section,
        session: session,
        finished: false,
        total_items: nil,
        imported_items: 0
      )
      |> put_component_assigns()

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

  @impl true
  def handle_info({:upload_file, path}, socket) do
    socket = path |> Tq2.Gdrive.upload_file() |> process_upload(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:read_titles, sheet_id}, socket) do
    socket = sheet_id |> read_titles(socket)

    {:noreply, socket}
  end

  @impl true
  def handle_info({event, _item_event}, %{assigns: %{imported_items: count}} = socket)
      when event in ~w(create_item_finished update_item_finished)a do
    {:noreply, assign(socket, imported_items: count + 1)}
  end

  @impl true
  def handle_info({event, _category_event}, socket)
      when event in ~w(create_category_finished update_category_finished)a do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:batch_import_finished, results}, socket) do
    successfully_imported_items =
      results
      |> Enum.filter(fn {status, _} -> status == :ok end)
      |> Enum.count()

    socket =
      socket
      |> assign(finished: true, import_items: successfully_imported_items)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:import, opts}, socket) do
    socket = socket |> import_items(opts)

    {:noreply, socket}
  end

  defp import_items(%{assigns: %{session: session}} = socket, %{sheet_id: sheet_id} = opts) do
    [_h | rows] = sheet_id |> Tq2.Gdrive.rows_for(opts[:grid_title])

    socket = socket |> assign(total_items: Enum.count(rows))

    Supervisor.start_link([{ItemImport, [session, rows, opts[:headers_with_index]]}],
      strategy: :one_for_one
    )

    socket
  end

  defp put_component_assigns(%{assigns: %{section: section}} = socket) do
    @section_components[section].put_component_assigns(socket)
  end

  defp translate_section("predefined") do
    dgettext("items", "Predefined")
  end

  defp translate_section("url") do
    dgettext("items", "Google spreadsheet")
  end

  defp translate_section("upload") do
    dgettext("items", "Upload spreadsheet")
  end

  defp translate_section("headers") do
    dgettext("items", "Select column headers")
  end

  defp component(section), do: @section_components[section]

  defp component_assigns(%{section: section} = assigns) do
    assigns |> Map.put(:id, "#{section}-component")
  end

  defp process_upload({:ok, %{id: id}}, socket) do
    id |> read_titles(socket)
  end

  defp process_upload(_, socket) do
    socket |> put_flash(:error, dgettext("items", "Can't upload file"))
  end

  defp read_titles(id, socket) do
    id
    |> Tq2.Gdrive.titles_for()
    |> process_titles(id, socket)
  end

  defp process_titles([_ | _] = titles, sheet_id, socket) do
    socket
    |> assign(
      column_titles: titles,
      sheet_id: sheet_id,
      section: "headers"
    )
  end

  defp process_titles(_response, _sheet_id, socket) do
    socket
    |> assign(:uploading, false)
    |> put_flash(:error, dgettext("items", "Can't read spreadsheet"))
  end
end
