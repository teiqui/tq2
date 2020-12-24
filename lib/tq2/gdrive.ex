defmodule Tq2.Gdrive do
  def titles(id) do
    session_for(id)
    |> GSS.Spreadsheet.sheets()
    |> Map.keys()
    |> Enum.sort()
  end

  def rows_for(id, title) do
    session = session_for(id, title)
    n = rows_number(session)

    iterate(session, n, [])
  end

  defp iterate(session, n, list) do
    count = Enum.count(list)

    case count >= n do
      true ->
        list

      _ ->
        init = count + 1

        max =
          case init + 100 do
            max when max >= n -> n
            max -> max
          end

        {:ok, results} = GSS.Spreadsheet.read_rows(session, init, max)

        iterate(session, n, list ++ results)
    end
  end

  defp rows_number(session) do
    {:ok, n} = GSS.Spreadsheet.rows(session)

    n
  end

  defp session_for(id, title \\ "") do
    # Title shouldn't be nil because it's cached with the first sheet
    {:ok, session} = GSS.Spreadsheet.Supervisor.spreadsheet(id, list_name: title)

    session
  end
end
