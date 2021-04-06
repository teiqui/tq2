defmodule Tq2Web.LayoutView do
  use Tq2Web, :view

  import Tq2.Utils.Urls, only: [store_uri: 0]

  alias Tq2.Accounts.Session
  alias Tq2.Inventories.Item
  alias Tq2.Shops.Store

  def locale do
    Tq2Web.Gettext
    |> Gettext.get_locale()
    |> String.replace(~r/_\w+/, "")
  end

  def app_subdomain?(%Plug.Conn{host: host}) do
    app_subdomain = Application.get_env(:tq2, :app_subdomain)

    String.starts_with?(host, app_subdomain)
  end

  def meta_og_tags(%{store: %Store{}} = assigns) do
    ~L"""
      <meta property="og:title" content="<%= store_title(assigns) %>">
      <meta property="og:site_name" content="<%= store_name(assigns) %>">
      <meta property="og:description" content="<%= og_store_description(assigns) %>">
      <meta property="og:type" content="website">
      <meta property="og:url" content="<%= og_store_url(assigns) %>">
      <meta property="og:image" content="<%= og_store_image_url(assigns) %>">
      <meta property="og:image:secure_url" content="<%= og_store_image_url(assigns) %>">
      <meta property="og:image:alt" content="<%= store_title(assigns) %>">
      <meta property="og:image:width" content="480">
      <meta property="og:image:height" content="480">
      <meta property="og:locale" content="<%= locale() %>">
      <meta property="og:updated_time" content="<%= System.os_time(:second) %>">
    """
  end

  def meta_og_tags(assigns) do
    ~L"""
      <meta property="og:title" content="<%= gettext("Teiqui") %>">
      <meta property="og:site_name" content="<%= gettext("Teiqui") %>">
      <meta property="og:description" content="<%= gettext("Teiqui - Online store") %>">
      <meta property="og:type" content="website">
      <meta property="og:url" content="<%= teiqui_url(@conn) %>">
      <meta property="og:image" content="<%= og_teiqui_image_url(@conn) %>">
      <meta property="og:image:secure_url" content="<%= og_teiqui_image_url(@conn) %>">
      <meta property="og:image:alt" content="<%= gettext("Teiqui") %>">
      <meta property="og:image:width" content="480">
      <meta property="og:image:height" content="480">
      <meta property="og:locale" content="<%= locale() %>">
      <meta property="og:updated_time" content="<%= System.os_time(:second) %>">
    """
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

  defp main_item(opts) do
    {text, opts} = Keyword.pop(opts, :text)
    {to, opts} = Keyword.pop(opts, :to)
    {icon, opts} = Keyword.pop(opts, :icon)
    {class, opts} = Keyword.pop(opts, :class, "text-light")
    {text_class, opts} = Keyword.pop(opts, :text_class)
    {icon_class, opts} = Keyword.pop(opts, :icon_class)

    link_opts =
      opts
      |> Keyword.get(:opts, [])
      |> Keyword.merge(to: to, class: "#{class} text-decoration-none")

    content = ~E"""
      <div class="mt-1 text-center">
        <span class="d-block btn-menu mx-auto <%= icon_class %>">
          <i class="bi-<%= icon %>"></i>
        </span>

        <span class="d-block <%= text_class %>">
          <%= text %>
        </span>
      </div>
    """

    link(content, link_opts)
  end

  defp menu(conn, %Session{account: account, user: user}) do
    render("_menu.html", conn: conn, account: account, user: user)
  end

  defp items_link_content do
    ~E"""
      <%= dgettext("items", "Items") %>

      <span class="tour-pointer d-block text-info-dark h1 mb-0 mt-n2">
        <i class="bi-caret-up-fill"></i>
      </span>
    """
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

  defp google_analytics_script(conn) do
    if Application.get_env(:tq2, :env) == :prod do
      key = google_analytics_key(conn)

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

  defp google_analytics_key(%Plug.Conn{} = conn) do
    subdomain = conn |> subdomain()

    keys = %{
      Application.get_env(:tq2, :web_subdomain) => "UA-163313653-1",
      Application.get_env(:tq2, :app_subdomain) => "UA-163313653-2",
      Application.get_env(:tq2, :store_subdomain) => "UA-163313653-3"
    }

    Map.get(keys, subdomain, "UA-163313653-1")
  end

  defp facebook_pixel_script do
    if Application.get_env(:tq2, :env) == :prod do
      ~E"""
        <script>
          !function (f, b, e, v, n, t, s) {
            if (f.fbq) return

            n = f.fbq = function () {
              n.callMethod ? n.callMethod.apply(n,arguments) : n.queue.push(arguments)
            }

            if (! f._fbq) f._fbq = n

            n.push    = n
            n.loaded  = !0
            n.version = '2.0'
            n.queue   = []
            t         = b.createElement(e)
            t.async   = !0
            t.src     = v
            s         = b.getElementsByTagName(e)[0]

            s.parentNode.insertBefore(t, s)
          }(window, document, 'script', 'https://connect.facebook.net/en_US/fbevents.js')

          fbq('init', '229888358772182')
          fbq('track', 'PageView')
        </script>
        <noscript>
          <img height="1"
               width="1"
               style="display:none"
               src="https://www.facebook.com/tr?id=229888358772182&ev=PageView&noscript=1">
        </noscript>
      """
    end
  end

  defp store_name(%{store: %Store{name: name}}) do
    [gettext("Teiqui"), name] |> Enum.join(" | ")
  end

  defp store_title(%{item: %Item{name: item_name}, store: %Store{name: name}}) do
    [gettext("Teiqui"), name, item_name]
    |> Enum.reject(fn v -> is_nil(v) or v == "" end)
    |> Enum.join(" | ")
    |> String.slice(0..59)
  end

  defp store_title(assigns) do
    assigns
    |> store_name()
    |> String.slice(0..59)
  end

  defp og_store_description(%{item: %Item{name: name, description: description}}) do
    [name, description]
    |> Enum.reject(fn v -> is_nil(v) or v == "" end)
    |> Enum.join(" | ")
    |> String.slice(0..159)
  end

  defp og_store_description(%{store: %Store{description: description}}) do
    (description || "")
    |> String.trim()
    |> String.slice(0..159)
  end

  defp og_store_url(%{item: %Item{} = item, store: %Store{} = store}) do
    store_uri() |> Routes.item_url(:index, store, item)
  end

  defp og_store_url(%{store: %Store{} = store}) do
    store_uri() |> Routes.counter_url(:index, store)
  end

  defp og_store_image_url(%{item: %Item{image: nil}} = assigns) do
    %{assigns | item: nil} |> og_store_image_url()
  end

  defp og_store_image_url(%{item: %Item{image: image} = item}) do
    Tq2.ImageUploader.url({image, item}, :og)
  end

  defp og_store_image_url(%{conn: conn, store: %Store{logo: nil}}) do
    conn |> Tq2Web.Router.Helpers.static_url("/images/og_store.jpg")
  end

  defp og_store_image_url(%{store: %Store{logo: logo} = store}) do
    Tq2.LogoUploader.url({logo, store}, :og)
  end

  defp og_teiqui_image_url(conn) do
    conn |> Tq2Web.Router.Helpers.static_url("/images/og_teiqui.jpg")
  end

  defp teiqui_url(conn) do
    conn |> Routes.root_url(:index)
  end

  defp icon_tag(icon) do
    content_tag(:i, nil, class: "bi-#{icon}")
  end

  defp search_input(assigns) do
    assigns = if assigns[:search], do: assigns, else: Map.put(assigns, :search, "")

    ~L"""
    <form>
      <div class="input-group mr-n2">
        <input type="text"
               name="search"
               value="<%= @search %>"
               class="form-control shadow-none"
               placeholder="<%= dgettext("filters", "Search...") %>"
               autocomplete="off"
               id="search-input">
        <div class="input-group-append">
          <button type="submit" class="btn btn-outline-primary px-2">
            <%= icon_tag("search") %>
          </button>
        </div>
      </div>
    </form>
    """
  end

  defp subdomain(%Plug.Conn{host: host}) do
    host |> String.split(".") |> List.first()
  end
end
