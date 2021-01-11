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

  describe "stripe for customer" do
    test "enqueue license update with id", %{conn: conn} do
      Exq.Mock.start_link(mode: :fake)

      assert Exq.Mock.jobs() == []

      path =
        Routes.webhook_path(
          conn,
          :stripe,
          %{"data" => %{"object" => %{"id" => "cus_123"}}}
        )

      conn = post(conn, path)

      json_response(conn, 200)

      jobs = Exq.Mock.jobs()

      assert Enum.count(jobs) == 1

      job = jobs |> List.first()

      assert job.class == Tq2.Workers.LicensesJob
      assert job.args == [:customer_id, "cus_123"]
    end

    test "enqueue license update with customer", %{conn: conn} do
      Exq.Mock.start_link(mode: :fake)

      assert Exq.Mock.jobs() == []

      path =
        Routes.webhook_path(
          conn,
          :stripe,
          %{"data" => %{"object" => %{"id" => "other_123", "customer" => "cus_123"}}}
        )

      conn = post(conn, path)

      json_response(conn, 200)

      jobs = Exq.Mock.jobs()

      assert Enum.count(jobs) == 1

      job = jobs |> List.first()

      assert job.class == Tq2.Workers.LicensesJob
      assert job.args == [:customer_id, "cus_123"]
    end
  end

  describe "stripe for subscription" do
    test "enqueue license update for id", %{conn: conn} do
      Exq.Mock.start_link(mode: :fake)

      assert Exq.Mock.jobs() == []

      path =
        Routes.webhook_path(
          conn,
          :stripe,
          %{"data" => %{"object" => %{"id" => "sub_123"}}}
        )

      conn = post(conn, path)

      json_response(conn, 200)

      jobs = Exq.Mock.jobs()

      assert Enum.count(jobs) == 1

      job = jobs |> List.first()

      assert job.class == Tq2.Workers.LicensesJob
      assert job.args == [:subscription_id, "sub_123"]
    end

    test "enqueue license update for subscription", %{conn: conn} do
      Exq.Mock.start_link(mode: :fake)

      assert Exq.Mock.jobs() == []

      path =
        Routes.webhook_path(
          conn,
          :stripe,
          %{"data" => %{"object" => %{"id" => "other_123", "subscription" => "sub_123"}}}
        )

      conn = post(conn, path)

      json_response(conn, 200)

      jobs = Exq.Mock.jobs()

      assert Enum.count(jobs) == 1

      job = jobs |> List.first()

      assert job.class == Tq2.Workers.LicensesJob
      assert job.args == [:subscription_id, "sub_123"]
    end
  end
end
