defmodule Tq2.Apps.WireTransferRepoTest do
  use Tq2.DataCase, async: true

  describe "wire_transfer" do
    import Tq2.Fixtures, only: [create_session: 0]

    alias Tq2.Apps
    alias Tq2.Apps.WireTransfer

    @valid_attrs %{
      "name" => "wire_transfer",
      "status" => "active",
      "data" => %{
        "description" => "Pay me",
        "account_number" => "123-123"
      }
    }

    test "converts unique constraint on name to error" do
      session = create_session()

      wire_transfer_fixture(session)

      changeset = Apps.change_app(session.account, %WireTransfer{}, @valid_attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:name, :account_id]]
      }

      assert expected == changeset.errors[:name]
    end

    defp wire_transfer_fixture(session) do
      {:ok, app} = Apps.create_app(session, @valid_attrs)

      app
    end
  end
end
