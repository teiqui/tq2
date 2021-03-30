defmodule Tq2.Repo.Migrations.AddPhoneToRegistrations do
  use Ecto.Migration

  def change do
    alter table(:registrations) do
      add :phone, :string
    end

    create unique_index(:registrations, :phone)
  end
end
