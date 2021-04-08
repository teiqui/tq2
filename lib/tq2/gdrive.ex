defmodule Tq2.Gdrive do
  def upload_file(path) do
    GoogleApi.Drive.V3.Api.Files.drive_files_create_simple(
      conn(),
      "multipart",
      %GoogleApi.Drive.V3.Model.File{
        mimeType: "application/vnd.google-apps.spreadsheet"
      },
      path
    )
  end

  def grid_titles(id) do
    case sheet(id) do
      {:ok, %{sheets: sheets}} -> sheets |> Enum.map(& &1.properties.title)
      _ -> :error
    end
  end

  def titles_for(id) do
    opts = [includeGridData: true, ranges: "1:1"]

    case sheet(id, opts) do
      {:ok, %{sheets: sheets}} -> sheets |> parse_sheets() |> List.first()
      _ -> :error
    end
  end

  def rows_for(id, grid \\ nil) do
    opts = [includeGridData: true, ranges: grid] |> Enum.filter(fn {_, v} -> v end)

    case sheet(id, opts) do
      {:ok, %{sheets: sheets}} -> sheets |> parse_sheets()
      _ -> :error
    end
  end

  defp token do
    {:ok, %{token: token}} = Goth.fetch(Tq2.Goth)

    token
  end

  defp conn do
    token() |> GoogleApi.Drive.V3.Connection.new()
  end

  defp sheet(id, opts \\ []) do
    GoogleApi.Sheets.V4.Api.Spreadsheets.sheets_spreadsheets_get(conn(), id, opts)
  end

  defp parse_sheets([%{data: data} | _]) do
    data
    |> List.first()
    |> Map.get(:rowData)
    |> Stream.map(& &1.values)
    |> Stream.filter(& &1)
    |> Stream.map(&formatted_row(&1))
    |> Stream.reject(&empty_row?(&1))
    |> Enum.to_list()
  end

  defp formatted_row(row) do
    row |> Enum.map(&formatted_cell(&1))
  end

  defp formatted_cell(%{effectiveValue: nil}), do: nil
  defp formatted_cell(%{effectiveValue: value}), do: value.stringValue || value.numberValue

  defp empty_row?(row), do: row |> Enum.all?(&(is_nil(&1) || &1 == 0))
end
