defmodule Tq2.Repo.Migrations.AddPriceTypeIndexToCarts do
  use Ecto.Migration

  def change do
    create index(:carts, :price_type)
  end
end
