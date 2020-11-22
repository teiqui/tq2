defmodule Tq2.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def up do
    create table(:items) do
      add :uuid, :uuid, null: false
      add :sku, :string
      add :name, :string, null: false
      add :description, :text
      add :visibility, :string, null: false
      add :price, :map
      add :promotional_price, :map
      add :cost, :map
      add :image, :string
      add :category_id, references(:categories, on_delete: :delete_all, on_update: :update_all)

      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:items, :name)
    create index(:items, :category_id)
    create index(:items, :account_id)
    create unique_index(:items, :uuid)
    create unique_index(:items, [:sku, :account_id])
    create unique_index(:items, [:name, :account_id])

    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    create index(:items, ["name gin_trgm_ops"], using: "GIN")
  end

  def down do
    drop index(:items, ["name gin_trgm_ops"], using: "GIN")

    execute "DROP EXTENSION IF EXISTS pg_trgm;"

    drop index(:items, :name)
    drop index(:items, :category_id)
    drop index(:items, :account_id)
    drop unique_index(:items, :uuid)
    drop unique_index(:items, [:sku, :account_id])
    drop unique_index(:items, [:name, :account_id])

    drop table(:items)
  end
end
