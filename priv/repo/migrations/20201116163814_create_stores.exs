defmodule Tq2.Repo.Migrations.CreateStores do
  use Ecto.Migration

  def change do
    create table(:stores) do
      add :uuid, :uuid, null: false
      add :name, :string, null: false
      add :description, :text
      add :slug, :string, null: false
      add :logo, :string
      add :published, :boolean, default: true, null: false
      add :data, :map
      add :configuration, :map
      add :location, :map

      add :account_id, references(:accounts, on_delete: :delete_all, on_update: :update_all),
        null: false

      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create index(:stores, :published)
    create index(:stores, :account_id)
    create unique_index(:stores, :uuid)
    create unique_index(:stores, :slug)
  end
end
