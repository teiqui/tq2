defmodule Tq2.Repo.Migrations.RemoveCostFromLines do
  use Ecto.Migration

  def change do
    alter table(:lines) do
      remove :cost, :map
    end
  end
end
