defmodule Tq2.Inventories.ItemImportTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [create_session: 0]

  describe "item import" do
    alias Tq2.Inventories.ItemImport

    test "batch_import/3 should create 1 item and notifies with default headers" do
      session = create_session()

      Tq2.Inventories.subscribe(session)

      # With untrusted https request
      rows = [
        [
          "  Water bottle  ",
          " Waters \n ",
          "100",
          "70",
          "50",
          "https://supermercadosvea.com.ar/caba/wp-content/uploads/sites/2/2021/02/Secundario_BSAS-NEA-1080x463-1.jpg"
        ]
      ]

      results =
        session
        |> ItemImport.batch_import(rows)
        |> Enum.filter(fn {status, _} -> status == :ok end)

      assert Enum.count(results) == 1

      {:ok, item} = hd(results)

      item = Tq2.Repo.preload(item, :category)

      assert item.name == "Water bottle"
      assert item.price == Money.new(10000, "ARS")
      assert item.promotional_price == Money.new(7000, "ARS")
      assert item.cost == Money.new(5000, "ARS")
      assert item.image.file_name
      assert item.category.name == "Waters"

      assert_received {:batch_import_finished, _results}
    end

    test "batch_import/3 should create 1 item with custom headers" do
      # With untrusted https request
      rows = [
        [
          "50",
          "  Water bottle  ",
          " Waters \n ",
          "70",
          "",
          "100"
        ]
      ]

      headers = %{
        name: 1,
        category: 2,
        price: 5,
        promotional_price: 3,
        cost: 0,
        url: 4,
        description: 6
      }

      results =
        create_session()
        |> ItemImport.batch_import(rows, headers)
        |> Enum.filter(fn {status, _} -> status == :ok end)

      assert Enum.count(results) == 1

      {:ok, item} = hd(results)

      item = Tq2.Repo.preload(item, :category)

      assert item.name == "Water bottle"
      assert item.price == Money.new(10000, "ARS")
      assert item.promotional_price == Money.new(7000, "ARS")
      assert item.cost == Money.new(5000, "ARS")
      assert item.category.name == "Waters"
      refute item.image
    end

    if System.get_env("CREDENTIALS_PATH") == nil, do: @tag(:skip)

    test "batch_import/3 should create 4 items with remote sheet" do
      [_h | rows] =
        :tq2
        |> Application.get_env(:default_sheet_id)
        |> Tq2.Gdrive.rows_for("Quesos y Fiambres")

      results =
        create_session()
        |> ItemImport.batch_import(rows)
        |> Enum.filter(fn {status, _} -> status == :ok end)

      assert Enum.count(results) == 4

      category_ids =
        results
        |> Enum.map(fn {:ok, i} -> i.category_id end)
        |> Enum.uniq()

      assert Enum.count(category_ids) == 1
    end
  end
end
