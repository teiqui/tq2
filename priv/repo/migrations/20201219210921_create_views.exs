defmodule Tq2.Repo.Migrations.CreateViews do
  use Ecto.Migration

  def change do
    create table(:views) do
      add :path, :string, null: false

      add :visit_id, references(:visits, on_delete: :delete_all, on_update: :update_all),
        null: false

      timestamps updated_at: false
    end

    create index(:views, :visit_id)
  end
end
