defmodule Tq2Web.Router do
  use Tq2Web, :router

  @session_extras %{
    current_session: {Tq2Web.SessionPlug, :session_extras, [:current_session]},
    registration: {Tq2Web.SessionPlug, :session_extras, [:registration]},
    store: {Tq2Web.SessionPlug, :session_extras, [:store]}
  }

  pipeline :csrf do
    plug :protect_from_forgery
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_session
    plug :check_locked_license
    plug :put_root_layout, {Tq2Web.LayoutView, :root}
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
    plug :fetch_store
    plug :fetch_token
    plug :track_visit
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :put_cache_control_headers
  end

  pipeline :pwa do
    plug :accepts, ["html", "json", "js"]
    plug :put_secure_browser_headers
    plug :put_cache_control_headers
  end

  scope "/", Tq2Web, host: Application.get_env(:tq2, :web_host) do
    pipe_through :browser

    get "/", PageController, :index
    get "/terms", LegalController, :index
    get "/:country", PageController, :index
  end

  scope "/", Tq2Web, host: "#{Application.get_env(:tq2, :store_subdomain)}." do
    pipe_through [:browser, :csrf, :store]

    put "/:slug/session/dismiss_price_info", Store.SessionController, :dismiss_price_info,
      as: :store_dismiss_price_info

    live "/:slug", Store.CounterLive, :index, session: @session_extras.store
    live "/:slug/items/:id", Store.ItemLive, :index, session: @session_extras.store
    live "/:slug/handing", Store.HandingLive, :index, session: @session_extras.store
    live "/:slug/customer", Store.CustomerLive, :index, session: @session_extras.store
    live "/:slug/payment", Store.PaymentLive, :index, session: @session_extras.store
    live "/:slug/payment/check", Store.PaymentCheckLive, :index, session: @session_extras.store
    live "/:slug/order/:id", Store.OrderLive, :index, session: @session_extras.store
    live "/:slug/team", Store.TeamLive, :index, session: @session_extras.store
    live "/:slug/checkout", Store.CheckoutLive, :index, session: @session_extras.store
    live "/:slug/brief", Store.BriefLive, :index, session: @session_extras.store

    get "/:slug/tokens/:token", TokenController, :show
  end

  scope "/", Tq2Web, host: "#{Application.get_env(:tq2, :store_subdomain)}." do
    pipe_through [:browser, :store]

    post "/:slug/payment/transbank", Store.PaymentController, :transbank, as: :transbank_payment
  end

  scope "/", Tq2Web do
    pipe_through :pwa

    get "/service-worker.js", PwaController, :service_worker
    get "/manifest.json", PwaController, :manifest
    get "/offline.html", PwaController, :offline
  end

  scope "/", Tq2Web do
    pipe_through [:browser, :csrf]

    get "/", RootController, :index
    get "/healthy", HealthController, :index

    resources(
      "/sessions",
      SessionController,
      only: [:new, :create, :delete],
      singleton: true
    )

    # Registration
    live "/registrations/new", Registration.NewLive, :index,
      as: "registration",
      session: @session_extras.registration

    get "/registrations/:uuid", RegistrationController, :show
    live "/tour", Registration.TourLive, :index
    live "/welcome", Registration.WelcomeLive, :index

    # Accounts
    resources "/accounts", AccountController, only: [:index, :show]
    resources "/users", UserController
    resources "/passwords", PasswordController, only: [:new, :create, :edit, :update]
    live "/license", Account.LicenseLive, :index

    # Apps
    resources "/apps", AppController, param: "name"

    # Dashboard
    live "/dashboard", Dashboard.MainLive, :index, as: :dashboard

    # Inventories
    resources "/categories", CategoryController
    resources "/items", ItemController
    live "/import", Inventory.ImportLive, :index

    # Shops
    live "/store/edit/:section", Shop.StoreLive, :index, session: @session_extras.current_session

    # Sales
    resources "/orders", OrderController, only: [:index, :show]
    live "/orders/:id/edit", Order.OrderEditLive, :index, session: @session_extras.current_session

    live "/orders/:id/payments", Order.PaymentLive, :index,
      as: :order_payment,
      session: @session_extras.current_session
  end

  # Other scopes may use custom stacks.
  scope "/api", Tq2Web do
    pipe_through :api

    post "/webhooks/mercado_pago", WebhookController, :mercado_pago
    post "/webhooks/stripe", WebhookController, :stripe
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
