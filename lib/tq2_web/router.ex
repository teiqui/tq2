defmodule Tq2Web.Router do
  use Tq2Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_session
    plug :put_root_layout, {Tq2Web.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_cache_control_headers

    if Application.get_env(:tq2, :env) == :prod do
      plug Tq2Web.SSLPlug,
        host: nil,
        hsts: true,
        preload: true,
        subdomains: true,
        rewrite_on: [:x_forwarded_proto]
    end
  end

  pipeline :store do
    plug :fetch_token
    plug :track_visit
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Tq2Web, host: "#{Application.get_env(:tq2, :web_subdomain)}." do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/", Tq2Web, host: "#{Application.get_env(:tq2, :store_subdomain)}." do
    pipe_through :browser
    pipe_through :store

    live "/:slug", Store.CounterLive, :index
    live "/:slug/items/:id", Store.ItemLive, :index
    live "/:slug/handing", Store.HandingLive, :index
    live "/:slug/customer", Store.CustomerLive, :index
    live "/:slug/payment", Store.PaymentLive, :index
    live "/:slug/payment/check", Store.PaymentCheckLive, :index
    live "/:slug/order/:id", Store.OrderLive, :index
  end

  scope "/", Tq2Web do
    pipe_through :browser

    get "/", RootController, :index
    get "/healthy", HealthController, :index

    resources(
      "/sessions",
      SessionController,
      only: [:new, :create, :delete],
      singleton: true
    )

    # Registration
    live "/registrations/new", Registration.NameLive, :index, as: "registration"

    live "/registrations/:uuid/email", Registration.EmailLive, :index, as: "registration_email"

    live "/registrations/:uuid/password", Registration.PasswordLive, :index,
      as: "registration_password"

    get "/registrations/:uuid", RegistrationController, :show
    live "/welcome", Registration.WelcomeLive, :index

    # Accounts
    resources "/accounts", AccountController
    resources "/users", UserController
    resources "/passwords", PasswordController, only: [:new, :create, :edit, :update]
    get "/license", LicenseController, :show
    get "/license/check", License.CheckController, :show, as: :license_check

    # Inventories
    resources "/categories", CategoryController
    resources "/items", ItemController
    live "/import", Inventories.ImportLive, :index

    # Shops
    resources "/store", StoreController,
      singleton: true,
      only: [:show, :new, :edit, :create, :update]

    # Apps
    get "/apps/mp_marketplace", Apps.MpMarketplaceController, :show, as: :mp_marketplace
    resources "/apps", AppController, param: "name"

    # Sales
    resources "/orders", OrderController, only: [:index, :show, :edit, :update]
    live "/orders/:id/payments", Order.PaymentLive, :index, as: :order_payment
  end

  # Other scopes may use custom stacks.
  scope "/api", Tq2Web do
    pipe_through :api

    post "/webhooks/mercado_pago", WebhookController, :mercado_pago, as: :mp_webhook
  end

  if Application.get_env(:tq2, :env) == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Application.get_env(:tq2, :env) in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/phx-dashboard", metrics: Tq2Web.Telemetry
    end
  end
end
