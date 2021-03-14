defmodule Tq2.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text, null: false
      add :originator, :string, null: false
      add :status, :string, null: false

      add :order_id, references(:orders, on_delete: :delete_all, on_update: :update_all),
        null: false

      timestamps updated_at: false, type: :utc_datetime
    end

    create index(:comments, :order_id)
  end
end
