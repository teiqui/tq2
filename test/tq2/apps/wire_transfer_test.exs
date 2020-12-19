defmodule Tq2.Apps.WireTransferTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [default_account: 0]

  describe "wire_transfer" do
    alias Tq2.Apps.WireTransfer

    @valid_attrs %{
      name: "wire_transfer",
      status: "active",
      data: %{
        "description" => "Pay me",
        "account_number" => "123-123"
      }
    }
    @invalid_attrs %{
      name: "wire_transfer",
      status: "unknown",
      data: %{}
    }

    test "changeset with valid attributes" do
      changeset = default_account() |> WireTransfer.changeset(%WireTransfer{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> WireTransfer.changeset(%WireTransfer{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      changeset = default_account() |> WireTransfer.changeset(%WireTransfer{}, @invalid_attrs)

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset check requires" do
      changeset = default_account() |> WireTransfer.changeset(%WireTransfer{}, @invalid_attrs)

      assert "can't be blank" in errors_on(changeset).data.description
      assert "can't be blank" in errors_on(changeset).data.account_number
    end

    test "changeset check length" do
      data = %{
        description: String.duplicate("a", 256),
        account_number: String.duplicate("a", 256)
      }

      attrs = %{@invalid_attrs | data: data}
      changeset = default_account() |> WireTransfer.changeset(%WireTransfer{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).data.description
      assert "should be at most 255 character(s)" in errors_on(changeset).data.account_number
    end
  end
end
