defmodule Tq2.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :lastname, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :password_reset_token, :string
      add :password_reset_sent_at, :utc_datetime
      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create unique_index(:users, :email)
    create unique_index(:users, :password_reset_token)
    create unique_index(:users, :password_reset_sent_at)
  end
end
