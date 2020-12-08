defmodule Tq2.Repo.Migrations.CreateLicensePayments do
  use Ecto.Migration

  def change do
    create table(:license_payments) do
      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :external_id, :string, null: false
      add :amount, :map, null: false
      add :status, :string, null: false
      add :paid_at, :utc_datetime
      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:license_payments, :account_id)
    create unique_index(:license_payments, :external_id)
  end
end
