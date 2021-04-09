defmodule Tq2.GdriveTest do
  use Tq2.DataCase, async: true

  unless System.get_env("CREDENTIALS_PATH"), do: @tag(:skip)

  test "grid_titles/id returns list with grid titles" do
    grids =
      :tq2
      |> Application.get_env(:default_sheet_id)
      |> Tq2.Gdrive.grid_titles()

    assert Enum.count(grids) == 17
    assert Enum.find(grids, &(&1 == "Quesos y Fiambres"))
  end

  unless System.get_env("CREDENTIALS_PATH"), do: @tag(:skip)

  test "titles_for/1 returns list with titles" do
    titles =
      :tq2
      |> Application.get_env(:default_sheet_id)
      |> Tq2.Gdrive.titles_for()

    assert [
             "Nombre del artículo",
             "Categoría",
             "Precio regular",
             "Precio Teiqui",
             "Dirección de la imagen"
           ] = titles
  end

  unless System.get_env("CREDENTIALS_PATH"), do: @tag(:skip)

  test "rows_for/1 returns list with rows" do
    rows =
      :tq2
      |> Application.get_env(:default_sheet_id)
      |> Tq2.Gdrive.rows_for()

    assert Enum.count(rows) > 4
  end

  unless System.get_env("CREDENTIALS_PATH"), do: @tag(:skip)

  test "rows_for/2 returns list with rows for specific grid" do
    rows =
      :tq2
      |> Application.get_env(:default_sheet_id)
      |> Tq2.Gdrive.rows_for("Quesos y Fiambres")

    assert Enum.count(rows) > 4
  end

  unless System.get_env("CREDENTIALS_PATH"), do: @tag(:skip)

  test "upload_file/1 returns a drive file" do
    file = "test/support/fixtures/files/test.csv"

    {:ok, gdrive_file} = file |> Tq2.Gdrive.upload_file()

    assert gdrive_file.id

    assert [["Name", 100, 90]] = Tq2.Gdrive.rows_for(gdrive_file.id)
  end
end
