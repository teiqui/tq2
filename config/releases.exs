# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :tq2, Tq2.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

app_host = Enum.join([System.get_env("APP_SUBDOMAIN", "app"), "teiqui.com"], ".")
store_host = Enum.join([System.get_env("STORE_SUBDOMAIN", "t2"), "teiqui.com"], ".")

config :tq2, Tq2Web.Endpoint,
  url: [host: app_host, scheme: "https", port: 443],
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  check_origin: ["https://#{app_host}", "https://#{store_host}"],
  secret_key_base: secret_key_base

# Public store's subdomain
config :tq2,
  store_subdomain: System.get_env("STORE_SUBDOMAIN", "t2"),
  default_sheet_id:
    System.get_env("DEFAULT_SHEET_ID", "1RFOEmiQvsMglWcMxCkGpoIc9d6nxvOwyerVVUw3RyIo")

# Sentry config
config :sentry, dsn: System.get_env("SENTRY_DSN")

# MercadoPago Credentials
config :tq2, :mp,
  ars_token: System.get_env("MP_ARS_TOKEN", ""),
  clp_token: System.get_env("MP_CLP_TOKEN", ""),
  cop_token: System.get_env("MP_COP_TOKEN", ""),
  mxn_token: System.get_env("MP_MXN_TOKEN", ""),
  pen_token: System.get_env("MP_PEN_TOKEN", "")

# Exq config
config :exq,
  url: System.get_env("REDIS_URL", "redis://localhost:6379")

# GDrive secrets
config :goth,
  json: System.get_env("CREDENTIALS_PATH", "config/credentials.sample.json") |> File.read!()

# AWS config
config :ex_aws,
  json_codec: Jason,
  s3: [region: {:system, "AWS_REGION"}]

# Bamboo config
config :tq2, Tq2.Notifications.Mailer,
  adapter: Bamboo.SesAdapter,
  ex_aws: [region: {:system, "AWS_REGION"}]

config :tq2, Tq2.Notifications.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: {:system, "SMTP_ADDRESS"},
  hostname: "teiqui.com",
  port: 587,
  username: {:system, "SMTP_USER_NAME"},
  password: {:system, "SMTP_PASSWORD"},
  tls: :always,
  ssl: false,
  retries: 5,
  auth: :always

# Waffle config
config :waffle,
  storage: Waffle.Storage.S3,
  bucket: {:system, "AWS_S3_BUCKET"},
  asset_host:
    Enum.join([
      "https://s3.",
      System.get_env("AWS_REGION", "sa-east-1"),
      ".amazonaws.com/",
      System.get_env("AWS_S3_BUCKET", "public.teiqui.com")
    ])

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :tq2, Tq2Web.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
