defmodule Tq2.Repo.Migrations.AddNameIndexToAccounts do
  use Ecto.Migration

  def change do
    create index(:accounts, :name)

    create index(:accounts, ["name gin_trgm_ops"], using: "GIN")
  end
end
