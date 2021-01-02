# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :tq2,
  ecto_repos: [Tq2.Repo]

# Configures the endpoint
config :tq2, Tq2Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "fB5cW3RnspBSLh9gpgzTufvQqDDZteuiXmKNOyWrueaPA4VCSTHbM8nWFyT+NMZW",
  render_errors: [view: Tq2Web.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Tq2.PubSub,
  live_view: [signing_salt: "t/+MFL7P"]

# Configures Elixir's Logger
config :logger,
  backends: [:console, Sentry.LoggerBackend],
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# PaperTrail config
config :paper_trail, repo: Tq2.Repo

# Gettext config
config :tq2, Tq2Web.Gettext, default_locale: "es"

# Ecto timestamps
config :tq2, Tq2.Repo, migration_timestamps: [type: :utc_datetime]

# Public store's subdomain
web_host = Enum.join([System.get_env("WEB_SUBDOMAIN", "www"), "teiqui.com"], ".")

config :tq2,
  app_subdomain: System.get_env("APP_SUBDOMAIN", "app"),
  store_subdomain: System.get_env("STORE_SUBDOMAIN", "tienda"),
  web_subdomain: System.get_env("WEB_SUBDOMAIN", "www"),
  web_host: web_host,
  default_sheet_id:
    System.get_env("DEFAULT_SHEET_ID", "1RFOEmiQvsMglWcMxCkGpoIc9d6nxvOwyerVVUw3RyIo")

# Scrivener HTML config
config :scrivener_html,
  routes_helper: Tq2Web.Router.Helpers,
  view_style: :bootstrap_v4

# Sentry config
config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  release: Application.spec(:tq2, :vsn),
  root_source_code_paths: [File.cwd!()],
  enable_source_code_context: true,
  environment_name: Mix.env(),
  included_environments: [:prod, :dev],
  report_deps: false,
  context_lines: 5,
  json_library: Jason

# Money config
config :money, symbol: false

# MercadoPago Credentials
config :tq2, :mp,
  ars_token: System.get_env("MP_ARS_TOKEN", ""),
  clp_token: System.get_env("MP_CLP_TOKEN", ""),
  cop_token: System.get_env("MP_COP_TOKEN", ""),
  mxn_token: System.get_env("MP_MXN_TOKEN", ""),
  pen_token: System.get_env("MP_PEN_TOKEN", "")

# Exq config
config :exq,
  url: System.get_env("REDIS_URL", "redis://localhost:6379"),
  namespace: "exq",
  concurrency: 100,
  queues: ["default"],
  scheduler_enable: true,
  max_retries: 25,
  json_library: Jason,
  start_on_application: false

# GDrive secrets
config :goth,
  json: System.get_env("CREDENTIALS_PATH", "config/credentials.sample.json") |> File.read!()

# GDrive client config
config :elixir_google_spreadsheets, :client,
  request_workers: 5,
  max_demand: 100,
  max_interval: :timer.minutes(1),
  interval: 100,
  max_rows_per_request: 20

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
