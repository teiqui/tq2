defmodule Tq2.Repo.Migrations.AddFavoriteToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :favorite, :boolean, default: false, null: false
    end

    create index(:items, :favorite)
  end
end
