defmodule Tq2Web.Registration.WelcomeLive do
  use Tq2Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
