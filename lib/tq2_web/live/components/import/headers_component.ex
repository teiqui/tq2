defmodule Tq2Web.Import.HeadersComponent do
  use Tq2Web, :live_component

  @impl true
  def handle_event(
        "import",
        %{"import" => %{"name" => _} = attrs},
        %{assigns: %{column_titles: column_titles, sheet_id: sheet_id}} = socket
      ) do
    socket =
      attrs
      |> valid_attrs?(column_titles)
      |> maybe_import(sheet_id, attrs, column_titles, socket)

    {:noreply, socket}
  end

  defp collection_options(column_titles) do
    [
      collection: column_titles,
      input_html: [prompt: dgettext("items", "None")]
    ]
  end

  defp submit_import do
    enable_text = dgettext("items", "Import")
    disable_text = dgettext("items", "Importing...")

    submit(enable_text,
      class: "btn btn-lg btn-block btn-primary",
      phx_disable_with: disable_text
    )
  end

  defp import_sheet(socket, sheet_id, attrs, column_titles) do
    headers =
      attrs
      |> Enum.filter(fn {_, v} -> v && String.length(v) > 0 end)
      |> Enum.map(fn {k, v} ->
        index = Enum.find_index(column_titles, fn name -> name == v end)

        {String.to_atom(k), index}
      end)
      |> Map.new()

    opts = %{
      headers_with_index: headers,
      sheet_id: sheet_id
    }

    send(self(), {:import, opts})

    socket
  end

  defp valid_attrs?(
         %{"name" => name, "price" => price, "promotional_price" => promotional_price},
         column_titles
       ) do
    Enum.all?(
      [name, price, promotional_price],
      fn value -> is_binary(value) && value in column_titles end
    )
  end

  defp valid_attrs?(_attrs, _column_titles), do: false

  defp maybe_import(true, sheet_id, attrs, column_titles, socket) do
    socket |> import_sheet(sheet_id, attrs, column_titles)
  end

  defp maybe_import(_, _sheet_id, _attrs, _column_titles, socket) do
    socket |> put_flash(:error, dgettext("items", "Need at least Name, Price and Teiqui price"))
  end
end
