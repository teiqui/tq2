defmodule Tq2.Repo.Migrations.AddTimestampIndexesToOrders do
  use Ecto.Migration

  def change do
    create index(:orders, :inserted_at)
    create index(:orders, :updated_at)
  end
end
