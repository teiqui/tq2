defmodule Tq2.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :status, :string, null: false
      add :promotion_expires_at, :utc_datetime, null: false
      add :data, :map

      add :cart_id, references(:carts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:orders, :status)
    create index(:orders, :promotion_expires_at)
    create index(:orders, :account_id)
    create unique_index(:orders, :cart_id)
  end
end
