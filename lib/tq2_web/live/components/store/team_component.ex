defmodule Tq2Web.Store.TeamComponent do
  use Tq2Web, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
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

  defp link_to_join(socket, store, referral_customer) do
    path = Routes.team_path(socket, :index, store)

    classes =
      if referral_customer do
        "btn btn-light btn-sm rounded-pill text-primary disabled"
      else
        "btn btn-light btn-sm rounded-pill text-primary"
      end

    live_redirect(dgettext("stores", "Join"), to: path, class: classes)
  end
end
