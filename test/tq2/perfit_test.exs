defmodule Tq2.PerfitTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [create_session: 0, user_fixture: 1]

  alias Tq2.Accounts
  alias Tq2.Perfit

  describe "perfit" do
    test "create contact with mock" do
      mock = [post: fn _, _, _ -> {:ok, %{body: Jason.encode!(%{data: %{id: 1234}})}} end]

      session = create_session()
      user = user_fixture(session)

      refute user.data

      with_mock HTTPoison, mock do
        Perfit.create_contact(%{session | user: user})
      end

      user = Accounts.get_user!(session.account, user.id)

      assert user.data
      assert user.data.external_id == 1234
    end

    unless System.get_env("CI"), do: @tag(:skip)

    test "create contact" do
      session = create_session()
      user = user_fixture(session)

      refute user.data

      Perfit.create_contact(%{session | user: user})

      user = Accounts.get_user!(session.account, user.id)

      assert user.data
      assert user.data.external_id
    end
  end
end
