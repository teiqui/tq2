defmodule Tq2.Apps.TransbankTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [default_account: 0]

  describe "transbank" do
    alias Tq2.Apps.Transbank
    alias Tq2.Gateways.Transbank, as: TbkClient

    @valid_attrs %{
      name: "transbank",
      status: "active",
      data: %{api_key: "123-asd-123", shared_secret: "asd"}
    }
    @invalid_attrs %{
      status: "unknown"
    }

    test "changeset with valid attributes" do
      mock = [check_credentials: fn _, _ -> :ok end]

      with_mock TbkClient, mock do
        changeset = default_account() |> Transbank.changeset(%Transbank{}, @valid_attrs)

        assert changeset.valid?
      end
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> Transbank.changeset(%Transbank{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      changeset = default_account() |> Transbank.changeset(%Transbank{}, @invalid_attrs)

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset validate embed data" do
      attrs = @valid_attrs |> Map.put(:data, %{})

      changeset = default_account() |> Transbank.changeset(%Transbank{}, attrs)

      refute changeset.valid?
      refute changeset.changes.data.valid?
      assert "can't be blank" in errors_on(changeset.changes.data).api_key
    end
  end
end
