defmodule Tq2.Repo.Migrations.AddTermsOfServiceToRegistrations do
  use Ecto.Migration

  def change do
    alter table(:registrations) do
      add :terms_of_service, :boolean, null: false, default: false
    end
  end
end
