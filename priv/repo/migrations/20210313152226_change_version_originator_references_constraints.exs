defmodule Tq2.Repo.Migrations.ChangeVersionOriginatorReferencesConstraints do
  use Ecto.Migration

  def change do
    alter table(:versions) do
      modify :originator_id, references(:users, on_delete: :delete_all, on_update: :update_all),
        from: references(:users)
    end
  end
end
