defmodule Tq2Web.CategoryView do
  use Tq2Web, :view
  use Scrivener.HTML

  def link_to_show(conn, category) do
    icon_link(
      conn,
      "eye-fill",
      title: dgettext("categories", "Show"),
      to: Routes.category_path(conn, :show, category),
      class: "ml-2"
    )
  end

  def link_to_edit(conn, category) do
    icon_link(
      conn,
      "pencil-fill",
      title: dgettext("categories", "Edit"),
      to: Routes.category_path(conn, :edit, category),
      class: "ml-2"
    )
  end

  def link_to_delete(conn, category) do
    icon_link(
      conn,
      "trash2-fill",
      title: dgettext("categories", "Delete"),
      to: Routes.category_path(conn, :delete, category),
      method: :delete,
      data: [confirm: dgettext("categories", "Are you sure?")],
      class: "ml-2 text-danger"
    )
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, category) do
    hidden_input(form, :lock_version, value: category.lock_version)
  end

  def submit_button(category) do
    category
    |> submit_label()
    |> submit(class: "btn btn-primary rounded-pill font-weight-semi-bold")
  end

  defp submit_label(nil), do: dgettext("categories", "Create")
  defp submit_label(_), do: dgettext("categories", "Update")
end
