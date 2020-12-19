defmodule Tq2.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments) do
      add :status, :string, null: false
      add :kind, :string, null: false
      add :amount, :map, null: false
      add :external_id, :string
      add :gateway_data, :map

      add :cart_id, references(:carts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:payments, :cart_id)
    create index(:payments, :external_id)
  end
end
