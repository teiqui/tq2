defmodule Tq2.Repo.Migrations.CreateWebhooks do
  use Ecto.Migration

  def change do
    create table(:webhooks) do
      add :name, :string, null: false
      add :payload, :map, null: false

      timestamps()
    end
  end
end
