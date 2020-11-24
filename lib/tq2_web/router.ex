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

    if Mix.env() == :prod do
      plug Plug.SSL,
        host: nil,
        hsts: true,
        preload: true,
        subdomains: true,
        rewrite_on: [:x_forwarded_proto]
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Tq2Web, host: "#{Application.get_env(:tq2, :store_subdomain)}." do
    pipe_through :browser

    live "/:slug", StoreLive, :index
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

    # Accounts
    resources "/accounts", AccountController
    resources "/users", UserController
    resources "/passwords", PasswordController, only: [:new, :create, :edit, :update]
    get "/license", LicenseController, :show

    # Inventories
    resources "/categories", CategoryController
    resources "/items", ItemController

    # Shops
    resources "/store", StoreController,
      singleton: true,
      only: [:show, :new, :edit, :create, :update]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Tq2Web do
  #   pipe_through :api
  # end
  #
  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/phx-dashboard", metrics: Tq2Web.Telemetry
    end
  end
end
