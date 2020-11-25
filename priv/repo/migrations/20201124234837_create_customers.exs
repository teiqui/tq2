defmodule Tq2.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :name, :string, null: false
      add :email, :string
      add :phone, :string
      add :address, :text
      add :lock_version, :integer, default: 0, null: false

      timestamps()
    end

    create unique_index(:customers, :email)
    create unique_index(:customers, :phone)
  end
end
