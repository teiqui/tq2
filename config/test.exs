use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :tq2, Tq2.Repo,
  username: "tq2",
  password: "tq2",
  database: "tq2_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Gettext config
config :tq2, Tq2Web.Gettext, default_locale: "en"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :tq2, Tq2Web.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
