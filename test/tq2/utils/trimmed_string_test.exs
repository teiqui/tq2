defmodule Tq2.Utils.TrimmedStringTest do
  use Tq2.DataCase, async: true

  alias Tq2.Utils.TrimmedString

  defmodule Schema do
    use Ecto.Schema

    schema "" do
      field :value, TrimmedString
    end

    def changeset(params, schema) do
      Ecto.Changeset.cast(schema, params, [:value])
    end
  end

  describe "trimmed string" do
    test "cast should return nil for nil" do
      changeset = Schema.changeset(%{value: nil}, %Schema{value: "something"})

      refute changeset.changes.value
    end

    test "cast should return nil for empty string" do
      changeset = Schema.changeset(%{value: ""}, %Schema{value: "something"})

      refute changeset.changes.value
    end

    test "cast should return trimmed string" do
      changeset = Schema.changeset(%{value: " other \n"}, %Schema{value: "something"})

      assert changeset.changes.value == "other"
    end

    test "cast should return error for not string values" do
      changeset = Schema.changeset(%{value: 123}, %Schema{value: "something"})

      assert {"is invalid", _} = changeset.errors[:value]
    end
  end
end
