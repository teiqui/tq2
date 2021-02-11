defmodule Tq2Web.PwaView do
  use Tq2Web, :view

  def render("manifest.json", %{conn: conn}) do
    %{
      name: gettext("Teiqui"),
      short_name: gettext("Teiqui"),
      description: dgettext("pwa", "Teiqui, online store that doubles your sales"),
      icons: [
        %{
          src: Routes.static_path(conn, "/images/logo_192.png"),
          type: "image/png",
          sizes: "192x192",
          purpose: "any maskable"
        },
        %{
          src: Routes.static_path(conn, "/images/logo_512.png"),
          type: "image/png",
          sizes: "512x512"
        }
      ],
      display: "fullscreen",
      start_url: Routes.session_url(conn, :new),
      scope: Routes.root_path(conn, :index),
      background_color: "#f04350",
      theme_color: "#f04350"
    }
  end
end
