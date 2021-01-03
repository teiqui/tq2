defmodule Tq2Web.LayoutView do
  use Tq2Web, :view

  import Phoenix.Controller, only: [get_flash: 2, current_path: 1]

  def locale do
    Tq2Web.Gettext
    |> Gettext.get_locale()
    |> String.replace(~r/_\w+/, "")
  end

  def menu_item(conn, [to: to], do: content) do
    current = current_path(conn)

    html_class =
      if String.starts_with?(current, to) do
        "nav-item active"
      else
        "nav-item"
      end

    content_tag(:li, class: html_class) do
      link(to: to, class: "nav-link", do: content)
    end
  end

  def hotjar_script do
    if Application.get_env(:tq2, :env) == :prod do
      ~E"""
        <script>
          (function (h, o, t, j, a, r) {
            h.hj          = h.hj || function () { (h.hj.q = h.hj.q || []).push(arguments) }
            h._hjSettings = { hjid: 1845634, hjsv: 6 }
            a             = o.getElementsByTagName('head')[0]
            r             = o.createElement('script')
            r.async       = 1
            r.src         = t + h._hjSettings.hjid + j + h._hjSettings.hjsv

            a.appendChild(r)
          })(window, document, 'https://static.hotjar.com/c/hotjar-', '.js?sv=')
        </script>
      """
    end
  end

  def google_analytics_script do
    if Application.get_env(:tq2, :env) == :prod do
      key = "UA-163313653-2"

      ~E"""
        <script async src="https://www.googletagmanager.com/gtag/js?id=<%= key %>"></script>
        <script>
          window.dataLayer = window.dataLayer || []

          function gtag () { dataLayer.push(arguments) }

          gtag('js', new Date())
          gtag('config', '<%= key %>')
          gtag('create', '<%= key %>', 'auto', { allowLinker: true })
          gtag('require', 'linker')
          gtag('linker:autoLink', ['teiqui.com'])
        </script>
      """
    end
  end
end
