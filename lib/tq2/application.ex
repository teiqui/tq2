defmodule Tq2.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        # Start the Ecto repository
        Tq2.Repo,
        # Start the Telemetry supervisor
        Tq2Web.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: Tq2.PubSub},
        # Start the Endpoint (http/https)
        Tq2Web.Endpoint,
        # Start Exq workers after Repo
        exq_spec()
        # Start a worker by calling: Tq2.Worker.start_link(arg)
        # {Tq2.Worker, arg}
      ]
      |> Enum.filter(& &1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tq2.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Tq2Web.Endpoint.config_change(changed, removed)
    :ok
  end

  # Exq supervisor spec
  def exq_spec do
    case Mix.env() do
      :test ->
        nil

      _ ->
        %{
          id: Exq,
          start: {Exq, :start_link, []}
        }
    end
  end
end
