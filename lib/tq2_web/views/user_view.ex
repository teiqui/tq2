defmodule Tq2Web.UserView do
  use Tq2Web, :view
  use Scrivener.HTML

  def link_to_show(conn, user) do
    icon_link(
      "eye-fill",
      title: dgettext("users", "Show"),
      to: Routes.user_path(conn, :show, user),
      class: "ml-2"
    )
  end

  def link_to_edit(conn, user) do
    icon_link(
      "pencil-fill",
      title: dgettext("users", "Edit"),
      to: Routes.user_path(conn, :edit, user),
      class: "ml-2"
    )
  end

  def link_to_delete(conn, user) do
    icon_link(
      "trash2-fill",
      title: dgettext("users", "Delete"),
      to: Routes.user_path(conn, :delete, user),
      method: :delete,
      data: [confirm: dgettext("users", "Are you sure?")],
      class: "ml-2 text-danger"
    )
  end

  def lock_version_input(_, nil), do: nil

  def lock_version_input(form, user) do
    hidden_input(form, :lock_version, value: user.lock_version)
  end

  def submit_button(user) do
    user
    |> submit_label()
    |> submit(class: "btn btn-primary rounded-pill font-weight-semi-bold")
  end

  defp submit_label(nil), do: dgettext("users", "Create")
  defp submit_label(_), do: dgettext("users", "Update")
end
