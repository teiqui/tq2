defmodule Tq2.Repo.Migrations.AddDataToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :data, :map
    end
  end
end
