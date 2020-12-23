defmodule Tq2.SchemaUtils do
  import Ecto.Changeset,
    only: [
      validate_change: 3,
      get_field: 2,
      add_error: 3,
      validate_required: 2
    ]

  def validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount >= 0 -> []
      _, _ -> [{field, {"must be greater than or equal to %{number}", number: 0}}]
    end)
  end

  def validate_at_least_one_active(changeset, fields, translate_fn) do
    case Enum.any?(fields, &get_field(changeset, &1)) do
      true ->
        changeset

      false ->
        translated_fields =
          fields
          |> Enum.map(&translate_fn.(&1))
          |> Enum.join(" / ")

        add_error(
          changeset,
          hd(fields),
          Gettext.dgettext(Tq2Web.Gettext, "errors", "must be at least one enabled: %{fields}",
            fields: translated_fields
          )
        )
    end
  end

  def validate_required_if_present(changeset, field, conditional_field) do
    case get_field(changeset, conditional_field) do
      true -> validate_required(changeset, [field])
      _ -> changeset
    end
  end
end
