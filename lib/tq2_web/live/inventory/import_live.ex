defmodule Tq2Web.Inventory.ImportLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts
  alias Tq2.Inventories
  alias Tq2.Inventories.{Item, ItemImport}

  @impl true
  def mount(_params, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)
    changeset = Inventories.change_item(session.account, %Item{})

    if connected?(socket), do: Inventories.subscribe(session)

    socket =
      socket
      |> assign(
        changeset: changeset,
        titles: titles(),
        account_id: account_id,
        user_id: user_id,
        title: nil,
        finished: false,
        total_items: nil,
        imported_items: 0
      )

    {:ok, socket, temporary_assigns: [changeset: nil, titles: []]}
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
  def handle_event("import", %{"item" => %{"title" => title}}, socket) do
    socket =
      socket
      |> import_items(title)
      |> assign(title: title)

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

  defp import_items(%{assigns: %{account_id: account_id, user_id: user_id}} = socket, title) do
    session = Accounts.get_current_session(account_id, user_id)
    [_h | rows] = default_sheet_id() |> Tq2.Gdrive.rows_for(title)

    socket = socket |> assign(total_items: Enum.count(rows))

    Supervisor.start_link([{ItemImport, [session, rows, nil]}], strategy: :one_for_one)

    socket
  end

  defp submit_import(total_items, finished) do
    enable_text = dgettext("items", "Import")
    disable_text = dgettext("items", "Importing...")
    disabled = total_items && !finished
    text = if disabled, do: disable_text, else: enable_text

    submit(text,
      class: "btn btn-lg btn-block btn-primary",
      disabled: disabled,
      phx_disable_with: disable_text
    )
  end

  defp titles do
    default_sheet_id()
    |> Tq2.Gdrive.titles()
    |> Enum.sort()
  end

  defp title_prompt do
    dgettext("items", "Select store type...")
  end

  defp default_sheet_id do
    :tq2 |> Application.get_env(:default_sheet_id)
  end
end
