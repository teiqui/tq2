defmodule Tq2.Repo.Migrations.CreateApps do
  use Ecto.Migration

  def change do
    create table(:apps) do
      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :name, :string, null: false
      add :status, :string, null: false
      add :data, :map, null: false
      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:apps, :account_id)
    create index(:apps, :data, using: "GIN")
    create unique_index(:apps, [:name, :account_id])
  end
end
