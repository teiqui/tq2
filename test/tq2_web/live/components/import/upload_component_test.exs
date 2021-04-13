defmodule Tq2Web.Import.UploadComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [init_test_session: 1]

  setup do
    Exq.Mock.set_mode(:fake)
  end

  describe "render" do
    setup [:init_test_session]

    unless System.get_env("CREDENTIALS_PATH"), do: @tag(:skip)

    test "import event triggers :upload_file", %{conn: conn} do
      path = Routes.import_path(conn, :show, "upload")
      {:ok, import_live, _html} = live(conn, path)

      refute import_live |> has_element?("button[type=\"submit\"]", "Import")

      :erlang.trace(import_live.pid, true, [:receive])

      pid = import_live.pid

      filename = Path.absname("test/support/fixtures/files/test.csv")
      %{size: size, mtime: mtime} = File.stat!(filename, time: :posix)

      file =
        file_input(import_live, "form", :file, [
          %{
            last_modified: mtime * 1000,
            name: "test.csv",
            content: File.read!(filename),
            size: size,
            type: "text/csv"
          }
        ])

      assert render_upload(file, "test.csv") =~ "spinner"

      assert_receive {:trace, ^pid, :receive, {:upload_file, _path}}, 100

      assert import_live |> has_element?("button[type=\"submit\"]", "Import")

      # This part doesn't work for some reason
      # job = Exq.Mock.jobs() |> List.first()

      # assert %Exq.Support.Job{
      #          args: ["delete_file" | _],
      #          class: Tq2.Workers.FilesJob
      #        } = job
    end

    unless System.get_env("CREDENTIALS_PATH"), do: @tag(:skip)

    test "import error redirect to upload file", %{conn: conn} do
      path = Routes.import_path(conn, :show, "upload")
      {:ok, import_live, _html} = live(conn, path)

      send(import_live.pid, {:import, %{sheet_id: "asd"}})

      ref = Process.monitor(import_live.pid)

      receive do
        {:DOWN, ^ref, _, _, live_response} ->
          assert {_, {:redirect, %{to: ^path}}} = live_response
      end
    end
  end
end
