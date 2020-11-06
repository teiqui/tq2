defmodule Tq2.Repo.Migrations.CreateMemberships do
  use Ecto.Migration

  def change do
    create table(:memberships) do
      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :user_id, references(:users, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :default, :boolean, default: false, null: false

      timestamps()
    end

    create index(:memberships, :account_id)
    create index(:memberships, :user_id)
    create index(:memberships, :default)
  end
end
