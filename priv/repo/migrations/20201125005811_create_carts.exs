defmodule Tq2.Repo.Migrations.CreateCarts do
  use Ecto.Migration

  def change do
    create table(:carts) do
      add :token, :string, null: false
      add :price_type, :string, null: false
      add :data, :map
      add :customer_id, references(:customers, on_delete: :delete_all, on_update: :update_all)

      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      timestamps()
    end

    create index(:carts, :token)
    create index(:carts, :customer_id)
    create index(:carts, :account_id)
  end
end
