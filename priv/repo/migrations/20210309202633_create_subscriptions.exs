defmodule Tq2.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :hash, :string, null: false
      add :error_count, :integer, null: false, default: 0
      add :data, :map, null: false

      timestamps type: :utc_datetime
    end

    create unique_index(:subscriptions, :hash)
  end
end
