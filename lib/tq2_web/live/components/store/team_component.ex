defmodule Tq2Web.Store.TeamComponent do
  use Tq2Web, :live_component

  def update(%{id: id, store: store}, socket) do
    socket =
      socket
      |> assign(id: id, store: store)

    {:ok, socket}
  end

  defp avatar(socket, extra_class \\ nil) do
    path = Routes.static_path(socket, "/images/store_default_logo.svg")

    img_tag(path,
      width: "32",
      height: "32",
      loading: "lazy",
      alt: dgettext("stores", "Users"),
      class: "rounded-circle #{extra_class}"
    )
  end
end
