defmodule Tq2.Repo do
  use Ecto.Repo,
    otp_app: :tq2,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
