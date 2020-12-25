defmodule Tq2.Repo.Migrations.ItemsNameWithUnaccentTrigram do
  use Ecto.Migration

  def up do
    drop index(:items, ["name gin_trgm_ops"], using: "GIN")
    create index(:items, ["immutable_unaccent(name) gin_trgm_ops"], using: "GIN")
  end

  def down do
    drop index(:items, ["immutable_unaccent(name) gin_trgm_ops"], using: "GIN")
    create index(:items, ["name gin_trgm_ops"], using: "GIN")
  end
end
