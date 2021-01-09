defmodule Tq2.Repo.Migrations.AddCustomerAndSubscriptionToLicense do
  use Ecto.Migration

  def change do
    drop index(:licenses, :reference)

    alter table(:licenses) do
      remove :reference, :uuid

      add :customer_id, :string
      add :subscription_id, :string
    end

    create unique_index(:licenses, :customer_id)
    create unique_index(:licenses, :subscription_id)
  end
end
