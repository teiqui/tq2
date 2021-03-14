defmodule Tq2.Repo.Migrations.CreateCustomersSubscriptions do
  use Ecto.Migration

  def change do
    create table(:customers_subscriptions) do
      add :subscription_id,
          references(:subscriptions, on_delete: :delete_all, on_update: :update_all),
          null: false

      add :customer_id, references(:customers, on_delete: :delete_all, on_update: :update_all),
        null: false

      timestamps()
    end

    create index(:customers_subscriptions, :subscription_id)
    create index(:customers_subscriptions, :customer_id)
  end
end
