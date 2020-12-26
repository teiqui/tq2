defmodule Tq2.Repo.Migrations.CreateUnaccentFunction do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS unaccent;"

    execute """
      CREATE OR REPLACE FUNCTION public.immutable_unaccent(text) RETURNS text AS $body$
        SELECT public.unaccent('public.unaccent', $1)
      $body$ LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT;
    """
  end

  def down do
    execute "DROP FUNCTION IF EXISTS public.immutable_unaccent;"
    execute "DROP EXTENSION IF EXISTS unaccent;"
  end
end
