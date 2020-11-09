defmodule Tq2.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
      add :ordinal, :integer, default: 0, null: false

      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:categories, :name)
    create index(:categories, :ordinal)
    create index(:categories, :account_id)
    create unique_index(:categories, [:name, :account_id])
  end
end
