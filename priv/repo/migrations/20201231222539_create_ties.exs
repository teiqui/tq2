defmodule Tq2.Repo.Migrations.CreateTies do
  use Ecto.Migration

  def change do
    create table(:ties) do
      add :order_id, references(:orders, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :originator_id, references(:orders, on_delete: :delete_all, on_update: :update_all),
        null: false

      timestamps()
    end

    create index(:ties, :order_id)
    create index(:ties, :originator_id)
  end
end
