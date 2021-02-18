defmodule Tq2.Repo.Migrations.RemoveTermsOfServiceFromRegistrations do
  use Ecto.Migration

  def change do
    alter table(:registrations) do
      remove :terms_of_service, :boolean, null: false, default: false
    end
  end
end
