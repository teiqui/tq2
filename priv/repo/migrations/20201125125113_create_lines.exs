defmodule Tq2.Repo.Migrations.CreateLines do
  use Ecto.Migration

  def change do
    create table(:lines) do
      add :name, :string, null: false
      add :quantity, :integer, default: 1, null: false
      add :price, :map, null: false
      add :promotional_price, :map, null: false
      add :cost, :map, null: false

      add :item_id, references(:items, on_delete: :nilify_all, on_update: :update_all)

      add :cart_id, references(:carts, on_delete: :delete_all, on_update: :update_all),
        null: false

      timestamps()
    end

    create index(:lines, :item_id)
    create index(:lines, :cart_id)
  end
end
