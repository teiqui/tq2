defmodule Tq2.Repo.Migrations.CreateVisits do
  use Ecto.Migration

  def change do
    create table(:visits) do
      add :slug, :string, null: false
      add :token, :string, null: false
      add :referral_token, :string
      add :utm_source, :string
      add :data, :map
      add :order_id, references(:orders, on_delete: :delete_all, on_update: :update_all)

      timestamps updated_at: false
    end

    create index(:visits, :slug)
    create index(:visits, :token)
    create index(:visits, :referral_token)
    create index(:visits, :inserted_at)
    create unique_index(:visits, :order_id)
  end
end
