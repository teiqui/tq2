defmodule Tq2.Apps.ConektaTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [default_account: 0]

  describe "conekta" do
    alias Tq2.Apps.Conekta
    alias Tq2.Gateways.Conekta, as: CktClient

    @valid_attrs %{
      name: "conekta",
      status: "active",
      data: %{api_key: "123-asd-123"}
    }
    @invalid_attrs %{
      status: "unknown"
    }

    test "changeset with valid attributes" do
      mock = [check_credentials: fn _ -> :ok end]

      with_mock CktClient, mock do
        changeset = default_account() |> Conekta.changeset(%Conekta{}, @valid_attrs)

        assert changeset.valid?
      end
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> Conekta.changeset(%Conekta{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset check inclusions" do
      changeset = default_account() |> Conekta.changeset(%Conekta{}, @invalid_attrs)

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset validate embed data" do
      attrs = @valid_attrs |> Map.put(:data, %{})
      changeset = default_account() |> Conekta.changeset(%Conekta{}, attrs)

      refute changeset.valid?
      refute changeset.changes.data.valid?
      assert "can't be blank" in errors_on(changeset.changes.data).api_key
    end
  end
end
