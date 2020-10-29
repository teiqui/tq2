defmodule Tq2.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :name, :string, null: false
      add :status, :string, null: false
      add :country, :string, null: false
      add :time_zone, :string, null: false
      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:accounts, :status)
    create index(:accounts, :country)
  end
end
