defmodule Tq2.Apps.Transbank.DataTest do
  use Tq2.DataCase

  import Mock

  describe "transbank data" do
    alias Tq2.Apps.Transbank.Data, as: TbkData
    alias Tq2.Gateways.Transbank, as: TbkClient

    @valid_attrs %{
      api_key: "123-asd-123",
      shared_secret: "123"
    }
    @invalid_attrs %{
      api_key: "",
      shared_secret: ""
    }

    test "changeset with valid attributes" do
      mock = [check_credentials: fn _, _ -> :ok end]

      with_mock TbkClient, mock do
        changeset = %TbkData{} |> TbkData.changeset(@valid_attrs)

        assert changeset.valid?
      end
    end

    test "changeset with invalid attributes" do
      changeset = %TbkData{} |> TbkData.changeset(@invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:api_key, String.duplicate("a", 101))
        |> Map.put(:shared_secret, String.duplicate("a", 101))

      changeset = %TbkData{} |> TbkData.changeset(attrs)

      assert "should be at most 100 character(s)" in errors_on(changeset).api_key
      assert "should be at most 100 character(s)" in errors_on(changeset).shared_secret
    end

    test "changeset remote check token" do
      mock = [check_credentials: fn _, _ -> {:error, :api_key, "Custom error"} end]

      with_mock TbkClient, mock do
        changeset = %TbkData{} |> TbkData.changeset(@valid_attrs)

        assert "Custom error" in errors_on(changeset).api_key
      end
    end
  end
end
