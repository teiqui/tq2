defmodule Tq2.Apps.Conekta.DataTest do
  use Tq2.DataCase

  import Mock

  describe "conekta data" do
    alias Tq2.Apps.Conekta.Data, as: CktData
    alias Tq2.Gateways.Conekta, as: CktClient

    @valid_attrs %{api_key: "123-asd-123"}
    @invalid_attrs %{api_key: ""}

    test "changeset with valid attributes" do
      mock = [check_credentials: fn _ -> :ok end]

      with_mock CktClient, mock do
        changeset = %CktData{} |> CktData.changeset(@valid_attrs)

        assert changeset.valid?
      end
    end

    test "changeset with invalid attributes" do
      changeset = %CktData{} |> CktData.changeset(@invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:api_key, String.duplicate("a", 101))

      changeset = %CktData{} |> CktData.changeset(attrs)

      assert "should be at most 100 character(s)" in errors_on(changeset).api_key
    end

    test "changeset remote check token" do
      mock = [check_credentials: fn _ -> {:error, "Custom error"} end]

      with_mock CktClient, mock do
        changeset = %CktData{} |> CktData.changeset(@valid_attrs)

        assert "Custom error" in errors_on(changeset).api_key
      end
    end
  end
end
