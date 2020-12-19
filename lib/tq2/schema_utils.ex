defmodule Tq2.SchemaUtils do
  import Ecto.Changeset, only: [validate_change: 3]

  def validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount >= 0 -> []
      _, _ -> [{field, {"must be greater than or equal to %{number}", number: 0}}]
    end)
  end
end
