defmodule Tq2.Repo.Migrations.CreateRegistrations do
  use Ecto.Migration

  def change do
    create table(:registrations) do
      add :uuid, :uuid, null: false
      add :name, :string, null: false
      add :type, :string, null: false
      add :email, :string

      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all)

      timestamps()
    end

    create unique_index(:registrations, :uuid)
    create unique_index(:registrations, :email)
    create unique_index(:registrations, :account_id)
  end
end
