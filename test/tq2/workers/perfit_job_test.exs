defmodule Tq2.Workers.PerfitJobTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [create_session: 0, create_item: 0, user_fixture: 1]

  alias Tq2.Accounts
  alias Tq2.Workers.PerfitJob

  describe "perfit job" do
    test "perform create contact with serialized session and mock" do
      mock = [post: fn _, _, _ -> {:ok, %{body: Jason.encode!(%{data: %{id: 1234}})}} end]

      session = create_session()
      user = user_fixture(session)
      deserialized_session = %{session | user: user} |> Jason.encode!() |> Jason.decode!()

      refute user.data

      with_mock HTTPoison, mock do
        PerfitJob.perform("create_contact", deserialized_session)
      end

      user = Accounts.get_user!(session.account, user.id)

      assert user.data
      assert user.data.external_id == 1234
    end

    unless System.get_env("CI"), do: @tag(:skip)

    test "perform create contact with serialized session" do
      session = create_session()
      user = user_fixture(session)
      deserialized_session = %{session | user: user} |> Jason.encode!() |> Jason.decode!()

      refute user.data

      PerfitJob.perform("create_contact", deserialized_session)

      user = Accounts.get_user!(session.account, user.id)

      assert user.data
      assert user.data.external_id
    end

    test "perform check empty items with serialized session and mock" do
      lists = [%{id: 123, name: "Test"}]

      mock = [
        put: fn _, _, _ ->
          {:ok, %{body: Jason.encode!(%{success: true, data: %{lists: lists}})}}
        end
      ]

      session = create_session()
      user = user_fixture(session)
      deserialized_session = %{session | user: user} |> Jason.encode!() |> Jason.decode!()

      with_mock HTTPoison, mock do
        refute PerfitJob.perform("check_empty_items", deserialized_session)
      end

      {:ok, _user} =
        Accounts.update_user(%{session | user: user}, user, %{data: %{external_id: 123}})

      with_mock HTTPoison, mock do
        assert %{"success" => true, "data" => %{"lists" => [%{"id" => 123, "name" => "Test"}]}} ==
                 PerfitJob.perform("check_empty_items", deserialized_session)
      end

      create_item()

      with_mock HTTPoison, mock do
        refute PerfitJob.perform("check_empty_items", deserialized_session)
      end
    end

    unless System.get_env("CI"), do: @tag(:skip)

    test "perform check empty items with serialized session" do
      session = create_session()
      user = user_fixture(session)
      deserialized_session = %{session | user: user} |> Jason.encode!() |> Jason.decode!()

      refute PerfitJob.perform("check_empty_items", deserialized_session)

      {:ok, _user} =
        Accounts.update_user(%{session | user: user}, user, %{data: %{external_id: 123}})

      assert %{"success" => true} = PerfitJob.perform("check_empty_items", deserialized_session)

      create_item()

      refute PerfitJob.perform("check_empty_items", deserialized_session)
    end
  end
end
