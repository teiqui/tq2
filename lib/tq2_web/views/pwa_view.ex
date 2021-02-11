defmodule Tq2Web.PwaView do
  use Tq2Web, :view

  def render("manifest.json", %{conn: conn}) do
    %{
      name: gettext("Teiqui"),
      short_name: gettext("Teiqui"),
      description: dgettext("pwa", "Teiqui, online store that doubles your sales"),
      display: "fullscreen",
      start_url: Routes.session_url(conn, :new),
      scope: Routes.root_path(conn, :index),
      background_color: "#f5f5f5",
      theme_color: "#f04350",
      icons: icons(conn)
    }
  end

  defp icons(conn) do
    ~w(48 72 96 144 168 192 512)
    |> Enum.map(fn size ->
      %{
        src: Routes.static_path(conn, "/images/icons/#{size}.png"),
        type: "image/png",
        sizes: "#{size}x#{size}",
        purpose: "any maskable"
      }
    end)
  end
end
