defmodule Tq2.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :value, :string

      add :customer_id, references(:customers, on_delete: :delete_all, on_update: :update_all),
        null: false

      timestamps()
    end

    create index(:tokens, :customer_id)
    create unique_index(:tokens, :value)
  end
end
