defmodule Tq2Web.WebhookControllerTest do
  use Tq2Web.ConnCase, async: true
  use Tq2.Support.LoginHelper

  describe "mercado pago" do
    test "create webhook", %{conn: conn} do
      Exq.Mock.start_link(mode: :fake)

      assert Exq.Mock.jobs() == []

      conn =
        post(conn, Routes.webhook_path(conn, :mercado_pago, %{user_id: 123, type: "payment"}))

      json_response(conn, 200)

      jobs = Exq.Mock.jobs()

      assert Enum.count(jobs) == 1

      job_class = jobs |> List.first() |> Map.fetch!(:class)

      assert job_class == Tq2.Workers.WebhooksJob
    end
  end
end
