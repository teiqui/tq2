defmodule Tq2.Workers.FilesJob do
  def perform("delete_file", id) do
    id |> Tq2.Gdrive.delete_file()
  end
end
