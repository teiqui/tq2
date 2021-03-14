defmodule Tq2.Repo.Migrations.CreateSubscriptionsUsers do
  use Ecto.Migration

  def change do
    create table(:subscriptions_users) do
      add :subscription_id,
          references(:subscriptions, on_delete: :delete_all, on_update: :update_all),
          null: false

      add :user_id, references(:users, on_delete: :delete_all, on_update: :update_all),
        null: false

      timestamps type: :utc_datetime
    end

    create index(:subscriptions_users, :subscription_id)
    create index(:subscriptions_users, :user_id)
  end
end
