defmodule Tq2Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :tq2

  plug Tq2Web.RemoteIpPlug

  use Sentry.PlugCapture

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_tq2_key",
    signing_salt: "zvi3Sf0e",
    same_site: "lax",
    max_age: 60 * 60 * 24 * 365
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :tq2,
    gzip: Application.get_env(:tq2, :env) == :prod,
    only: ~w(css fonts images js robots.txt .well-known/assetlinks.json)

  if Application.get_env(:waffle, :storage) == Waffle.Storage.Local do
    plug Plug.Static,
      at: "/images",
      from: Path.expand("./priv/waffle/private/images"),
      gzip: false

    plug Plug.Static,
      at: "/logos",
      from: Path.expand("./priv/waffle/private/logos"),
      gzip: false
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :tq2
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Sentry.PlugContext
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug Tq2Web.Router
end
