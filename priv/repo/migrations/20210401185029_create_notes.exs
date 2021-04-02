defmodule Tq2.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :title, :string, null: false
      add :body, :text, null: false
      add :publish_at, :date, null: false
      add :lock_version, :integer, default: 0, null: false

      timestamps type: :utc_datetime
    end

    create index(:notes, :publish_at)
  end
end
