defmodule Tq2.Repo.Migrations.AddVisitsToCarts do
  use Ecto.Migration

  def change do
    alter table(:carts) do
      add :visit_id, references(:visits, on_delete: :delete_all, on_update: :update_all),
        null: false
    end
  end
end
