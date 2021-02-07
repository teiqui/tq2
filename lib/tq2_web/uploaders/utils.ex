defmodule Tq2.Uploaders.Utils do
  defmacro __using__(opts \\ []) do
    output_extension = opts[:output_extension] || :png

    quote do
      def reprocess_version({file, scope}, version) do
        image =
          {file, scope}
          |> url(:original)
          |> Waffle.File.new(__MODULE__)
          |> Map.put(:file_name, "#{version}.#{unquote(output_extension)}")

        case Waffle.Processor.process(__MODULE__, version, {image, scope}) do
          {:ok, processed_file} ->
            case __storage().put(__MODULE__, version, {processed_file, scope}) do
              {:ok, result} -> result
              _ -> nil
            end

          _ ->
            nil
        end
      end
    end
  end
end
