defmodule Tq2.Repo.Migrations.RemoveSkuAndCostFromItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      remove :sku, :string
      remove :cost, :map
    end
  end
end
