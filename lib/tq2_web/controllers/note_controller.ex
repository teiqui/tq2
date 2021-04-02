defmodule Tq2Web.NoteController do
  use Tq2Web, :controller

  alias Tq2.News
  alias Tq2.News.Note

  plug :authenticate
  plug :authorize, as: :admin

  def action(%{assigns: %{current_session: session}} = conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, session])
  end

  def index(conn, params, _session) do
    page = News.list_notes(params)

    render_index(conn, page)
  end

  def new(conn, _params, _session) do
    changeset = News.change_note(%Note{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"note" => note_params}, session) do
    case News.create_note(session, note_params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, dgettext("notes", "Note created successfully."))
        |> redirect(to: Routes.note_path(conn, :show, note))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, _session) do
    note = News.get_note!(id)

    render(conn, "show.html", note: note)
  end

  def edit(conn, %{"id" => id}, _session) do
    note = News.get_note!(id)
    changeset = News.change_note(note)

    render(conn, "edit.html", note: note, changeset: changeset)
  end

  def update(conn, %{"id" => id, "note" => note_params}, session) do
    note = News.get_note!(id)

    case News.update_note(session, note, note_params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, dgettext("notes", "Note updated successfully."))
        |> redirect(to: Routes.note_path(conn, :show, note))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", note: note, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, session) do
    note = News.get_note!(id)
    {:ok, _note} = News.delete_note(session, note)

    conn
    |> put_flash(:info, dgettext("notes", "Note deleted successfully."))
    |> redirect(to: Routes.note_path(conn, :index))
  end

  defp render_index(conn, %{total_entries: 0}), do: render(conn, "empty.html")

  defp render_index(conn, page) do
    render(conn, "index.html", notes: page.entries, page: page)
  end
end
