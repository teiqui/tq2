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
        exq_spec(),
        # Start Goth supervisor
        goth_spec()
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
    case Application.get_env(:exq, :queue_adapter) do
      Exq.Adapters.Queue.Mock ->
        nil

      _ ->
        %{
          id: Exq,
          start: {Exq, :start_link, []}
        }
    end
  end

  # Goth supervisor spec
  def goth_spec do
    path = System.get_env("CREDENTIALS_PATH")

    if path do
      credentials = path |> File.read!() |> Jason.decode!()

      scopes = [
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive.file"
      ]

      source = {:service_account, credentials, scopes: scopes}

      {Goth, name: Tq2.Goth, source: source}
    end
  end
end
