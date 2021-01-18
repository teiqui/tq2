defmodule Tq2Web.LayoutView do
  use Tq2Web, :view

  def locale do
    Tq2Web.Gettext
    |> Gettext.get_locale()
    |> String.replace(~r/_\w+/, "")
  end

  defp body_classes(_conn, nil) do
    "mt-4 mb-5 bg-light"
  end

  defp body_classes(conn, _current_session) do
    bg_color =
      if conn.request_path == Routes.dashboard_path(conn, :index) do
        "bg-primary"
      else
        "bg-light"
      end

    "mt-4 mb-5 pt-5 #{bg_color}"
  end

  defp main_item(conn, opts) do
    {text, opts} = Keyword.pop(opts, :text)
    {to, opts} = Keyword.pop(opts, :to)
    {icon, opts} = Keyword.pop(opts, :icon)
    {class, opts} = Keyword.pop(opts, :class, "text-light")
    {text_class, opts} = Keyword.pop(opts, :text_class)
    {icon_class, opts} = Keyword.pop(opts, :icon_class)
    {icon_size, opts} = Keyword.pop(opts, :icon_size, 25)

    link_opts =
      opts
      |> Keyword.get(:opts, [])
      |> Keyword.merge(to: to, class: "#{class} text-decoration-none")

    content = ~E"""
      <div class="mt-1 text-center">
        <span class="d-block btn-menu mx-auto <%= icon_class %>">
          <svg class="bi" width="<%= icon_size %> " height="<%= icon_size %>" fill="currentColor">
            <use xlink:href="<%= Routes.static_path(conn, "/images/bootstrap-icons.svg##{icon}") %>"/>
          </svg>
        </span>

        <span class="d-block <%= text_class %>">
          <%= text %>
        </span>
      </div>
    """

    link(content, link_opts)
  end

  defp hotjar_script do
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

  defp google_analytics_script do
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
