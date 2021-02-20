defmodule Tq2.Workers.PerfitJobTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [create_session: 0, user_fixture: 1]

  alias Tq2.Accounts
  alias Tq2.Workers.PerfitJob

  describe "perfit job" do
    test "perform with serialized session and mock" do
      mock = [post: fn _, _, _ -> {:ok, %{body: Jason.encode!(%{data: %{id: 1234}})}} end]

      session = create_session()
      user = user_fixture(session)
      deserialized_session = %{session | user: user} |> Jason.encode!() |> Jason.decode!()

      refute user.data

      with_mock HTTPoison, mock do
        PerfitJob.perform(deserialized_session)
      end

      user = Accounts.get_user!(session.account, user.id)

      assert user.data
      assert user.data.external_id == 1234
    end

    unless System.get_env("CI"), do: @tag(:skip)

    test "perform with serialized session" do
      session = create_session()
      user = user_fixture(session)
      deserialized_session = %{session | user: user} |> Jason.encode!() |> Jason.decode!()

      refute user.data

      PerfitJob.perform(deserialized_session)

      user = Accounts.get_user!(session.account, user.id)

      assert user.data
      assert user.data.external_id
    end
  end
end
