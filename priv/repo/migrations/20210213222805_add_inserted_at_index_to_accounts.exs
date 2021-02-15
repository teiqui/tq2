defmodule Tq2.Repo.Migrations.AddInsertedAtIndexToAccounts do
  use Ecto.Migration

  def change do
    create index(:accounts, :inserted_at)
  end
end
