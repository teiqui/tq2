defmodule Tq2.Repo.Migrations.ChangeItemCategoryReferenceConstraints do
  use Ecto.Migration

  def change do
    alter table(:items) do
      modify :category_id,
             references(:categories, on_delete: :nilify_all, on_update: :update_all),
             from: references(:categories, on_delete: :delete_all, on_update: :update_all)
    end
  end
end
