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
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Gettext config
config :tq2, Tq2Web.Gettext, default_locale: "es"

# Ecto timestamps
config :tq2, Tq2.Repo, migration_timestamps: [type: :utc_datetime]

# Scrivener HTML config
config :scrivener_html,
  routes_helper: Tq2Web.Router.Helpers,
  view_style: :bootstrap_v4

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
