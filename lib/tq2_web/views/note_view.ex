defmodule Tq2Web.NoteView do
  use Tq2Web, :view
  use Scrivener.HTML

  import Tq2Web.Utils, only: [localize_date: 1]

  def link_to_show(conn, note) do
    icon_link(
      "eye-fill",
      title: dgettext("notes", "Show"),
      to: Routes.note_path(conn, :show, note),
      class: "ml-2"
    )
  end

  def link_to_edit(conn, note) do
    icon_link(
      "pencil-fill",
      title: dgettext("notes", "Edit"),
      to: Routes.note_path(conn, :edit, note),
      class: "ml-2"
    )
  end

  def link_to_delete(conn, note) do
    icon_link(
      "trash2-fill",
      title: dgettext("notes", "Delete"),
      to: Routes.note_path(conn, :delete, note),
      method: :delete,
      data: [confirm: dgettext("notes", "Are you sure?")],
      class: "ml-2 text-danger"
    )
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, note) do
    hidden_input(form, :lock_version, value: note.lock_version)
  end

  def submit_button(note) do
    note
    |> submit_label()
    |> submit(class: "btn btn-primary rounded-pill font-weight-semi-bold")
  end

  defp submit_label(nil), do: dgettext("notes", "Create")
  defp submit_label(_), do: dgettext("notes", "Update")
end
