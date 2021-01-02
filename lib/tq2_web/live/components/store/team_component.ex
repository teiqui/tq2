defmodule Tq2Web.Store.TeamComponent do
  use Tq2Web, :live_component

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp avatar(socket, referral_customer) do
    image_path = image_path(referral_customer)
    path = Routes.static_path(socket, image_path)

    img_tag(path,
      width: "60",
      height: "32",
      loading: "lazy",
      alt: dgettext("stores", "Users")
    )
  end

  defp link_to_join(socket, store, referral_customer) do
    path = Routes.team_path(socket, :index, store)

    classes =
      if referral_customer do
        "btn btn-light btn-sm rounded-pill text-primary disabled"
      else
        # TODO: remove disabled class when Team Live View works and uncomment refute on test
        "btn btn-light btn-sm rounded-pill text-primary disabled"
      end

    live_redirect(dgettext("stores", "Join"), to: path, class: classes)
  end

  defp image_path(nil) do
    # For some weird reason :random.uniform/1 does not work here
    index = DateTime.utc_now() |> DateTime.to_unix() |> Integer.mod(2)

    "/images/avatars/avatar_#{index + 1}.svg"
  end

  defp image_path(_), do: "/images/avatars/avatar_join.svg"
end
