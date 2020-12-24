defmodule Tq2.Inventories.ItemImport do
  alias Tq2.Inventories
  alias Tq2.Accounts.{Account, Session}

  @default_headers %{
    name: 0,
    category: 1,
    price: 2,
    promotional_price: 3,
    cost: 4,
    url: 5
  }

  @money_fields [:price, :promotional_price, :cost]

  def batch_import(
        %Session{} = session,
        rows,
        headers_with_index \\ @default_headers
      ) do
    categories_by_name =
      session
      |> categories_from_rows(rows, headers_with_index)

    rows
    |> Enum.map(&row_to_item(&1, session.account, categories_by_name, headers_with_index))
    |> Enum.map(&Inventories.create_or_update_item(session, &1))
  end

  defp categories_from_rows(session, rows, headers_with_index) do
    rows
    |> Enum.map(&field_value(&1, :category, headers_with_index))
    |> Enum.uniq()
    |> Enum.map(&get_or_create_category(&1, session))
    |> Enum.filter(fn {status, _} -> status == :ok end)
    |> Enum.map(fn {_, category} -> {category.name, category.id} end)
    |> Map.new()
  end

  defp field_value(_, _, _, _ \\ nil)

  defp field_value(row, field, headers_with_index, currency) when field in @money_fields do
    row
    |> Enum.at(headers_with_index[field])
    |> String.trim()
    |> Money.parse!(currency)
  end

  defp field_value(row, field, headers_with_index, _) do
    row
    |> Enum.at(headers_with_index[field])
    |> String.trim()
  end

  defp row_to_item(row, account, category_ids, headers_with_index) do
    currency = Account.currency(account)

    attrs =
      [:name, :price, :promotional_price, :cost]
      |> Enum.map(fn k -> {k, field_value(row, k, headers_with_index, currency)} end)
      |> Map.new()

    image =
      row
      |> field_value(:url, headers_with_index)
      |> image_from_url(attrs.name)

    category = row |> field_value(:category, headers_with_index)

    Map.merge(%{
      image: image,
      category_id: category_ids[category]
    }, attrs)
  end

  defp image_from_url(url, _) when url in [nil, ""], do: nil

  defp image_from_url(url, name) do
    # Similar than Waffle internal url handle
    case HTTPoison.get(url, [], hackney: [:insecure]) do
      {:ok, %HTTPoison.Response{body: body}} -> plug_upload_file(url, name, body)
      _ -> nil
    end
  end

  defp get_or_create_category(name, session) do
    session |> Inventories.get_or_create_category_by_name(%{name: name})
  end

  defp file_name_from_url(url, name) do
    ext =
      url
      |> String.replace(~r"\?.*", "")
      |> Path.extname()

    name
    |> String.replace(~r"[^A-z]+", "-")
    |> Kernel.<>(ext)
  end

  defp plug_upload_file(url, name, body) do
    file_name = file_name_from_url(url, name)
    tmp = Waffle.File.generate_temporary_path(file_name)

    case File.write(tmp, body) do
      :ok ->
        %Plug.Upload{
          path: tmp,
          filename: file_name,
          content_type: MIME.from_path(file_name)
        }

      _ ->
        nil
    end
  end
end
