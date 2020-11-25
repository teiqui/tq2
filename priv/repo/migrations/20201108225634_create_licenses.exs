defmodule Tq2.Repo.Migrations.CreateLicenses do
  use Ecto.Migration

  def change do
    create table(:licenses) do
      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :status, :string, null: false
      add :reference, :uuid, null: false
      add :paid_until, :date, null: false
      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:licenses, :account_id)
    create unique_index(:licenses, :reference)
  end
end
