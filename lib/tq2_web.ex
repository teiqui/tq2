defmodule Tq2Web do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use Tq2Web, :controller
      use Tq2Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: Tq2Web

      alias Tq2Web.Router.Helpers, as: Routes

      import Plug.Conn
      import Tq2Web.Gettext
      import Tq2Web.SessionPlug, only: [authenticate: 2]
      import Tq2Web.AuthorizationPlug, only: [authorize: 2]
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/tq2_web/templates",
        namespace: Tq2Web

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {Tq2Web.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
      import Tq2Web.CacheControlPlug, only: [put_cache_control_headers: 2]
      import Tq2Web.LicenseCheckPlug, only: [check_locked_license: 2]
      import Tq2Web.SessionPlug, only: [fetch_current_session: 2, put_remote_ip: 2]
      import Tq2Web.StorePlug, only: [fetch_store: 2]
      import Tq2Web.TokenPlug, only: [fetch_token: 2]
      import Tq2Web.VisitPlug, only: [track_visit: 2]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import Tq2Web.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import Tq2Web.ErrorHelpers
      import Tq2Web.Gettext
      import Tq2Web.InputHelpers
      import Tq2Web.LinkHelpers
      alias Tq2Web.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
