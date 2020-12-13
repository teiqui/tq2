defmodule Tq2.MixProject do
  use Mix.Project

  def project do
    [
      app: :tq2,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Tq2.Application, []},
      extra_applications: [:logger, :runtime_tools, :exq]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, ">= 1.5.7", override: true},
      {:phoenix_ecto, ">= 4.1.0"},
      {:ecto_sql, ">= 3.4.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, ">= 0.15.0"},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_html, ">= 2.11.0"},
      {:phoenix_live_reload, ">= 1.3.0", only: :dev},
      {:phoenix_live_dashboard, ">= 0.4.0"},
      {:telemetry_metrics, ">= 0.6.0"},
      {:telemetry_poller, ">= 0.4.0"},
      {:gettext, ">= 0.11.0"},
      {:jason, ">= 1.0.0"},
      {:plug_cowboy, ">= 2.4.0"},
      {:argon2_elixir, ">= 2.3.0"},
      {:bamboo, ">= 1.6.0"},
      {:paper_trail, ">= 0.11.0"},
      {:tzdata, ">= 1.0.0"},
      {:scrivener_ecto, ">= 2.7.0"},
      {:scrivener_html, ">= 1.8.0"},
      {:sentry, ">= 8.0.0"},
      {:timex, ">= 3.6.0"},
      {:money, ">= 1.8.0"},
      {:waffle_ecto, ">= 0.0.9"},
      {:ex_aws_s3, ">= 2.1.0"},
      {:sweet_xml, ">= 0.6.0"},
      {:httpoison, ">= 1.7.0"},
      {:mock, ">= 0.3.6", only: :test},
      # Exq has poison as optional, but it's been installed
      {:exq, ">= 0.14.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd yarn install --cwd assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "run priv/repo/test_seeds.exs",
        "test"
      ]
    ]
  end
end
