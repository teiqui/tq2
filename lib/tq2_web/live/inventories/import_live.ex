defmodule Tq2Web.Inventories.ImportLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts
  alias Tq2.Inventories
  alias Tq2.Inventories.{Item, ItemImport}

  @impl true
  def mount(_params, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)
    changeset = Inventories.change_item(session.account, %Item{})

    socket =
      socket
      |> assign(
        changeset: changeset,
        titles: titles(),
        account_id: account_id,
        user_id: user_id,
        imported_items: 0
      )

    {:ok, socket, temporary_assigns: [changeset: nil, titles: []]}
  end

  @impl true
  def handle_event(
        "import",
        %{"item" => %{"title" => title}},
        %{assigns: %{account_id: account_id, user_id: user_id}} = socket
      ) do
    session = Accounts.get_current_session(account_id, user_id)
    [_h | spreadsheet] = default_sheet_id() |> Tq2.Gdrive.rows_for(title)

    results =
      session
      |> ItemImport.batch_import(spreadsheet)
      |> Enum.filter(fn {status, _} -> status == :ok end)

    socket =
      socket
      |> assign(imported_items: Enum.count(results))

    {:noreply, socket}
  end

  defp titles do
    default_sheet_id() |> Tq2.Gdrive.titles()
  end

  defp title_prompt do
    dgettext("items", "Select store type...")
  end

  defp default_sheet_id do
    :tq2 |> Application.get_env(:default_sheet_id)
  end
end
