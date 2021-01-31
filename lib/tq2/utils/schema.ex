defmodule Tq2.Utils.Schema do
  import Tq2Web.Gettext, only: [dgettext: 3]

  import Tq2.Utils.CountryCurrency, only: [valid_phone?: 2]

  import Ecto.Changeset,
    only: [
      add_error: 3,
      get_field: 2,
      validate_change: 3,
      validate_number: 3,
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
          dgettext("errors", "must have at least one enabled: %{fields}",
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

  def validate_required_if_field_has_value(changeset, field, conditional_field, conditional_value) do
    case get_field(changeset, conditional_field) == conditional_value do
      true -> validate_required(changeset, [field])
      _ -> changeset
    end
  end

  def validate_less_than_money_field(changeset, field, conditional_field) do
    validate_number_with_value(
      changeset,
      field,
      get_field(changeset, field),
      get_field(changeset, conditional_field)
    )
  end

  defp validate_number_with_value(changeset, field, %Money{}, %Money{} = value) do
    msg =
      dgettext(
        "errors",
        "must be less than %{number}",
        number: Money.to_decimal(value)
      )

    changeset |> validate_number(field, less_than: value, message: msg)
  end

  defp validate_number_with_value(changeset, _, _, _), do: changeset

  def validate_at_least_one_embed_if_active(changeset, embed_field, field_condition, message_fn) do
    case get_field(changeset, field_condition) do
      true ->
        embed_values = get_field(changeset, embed_field) || []

        case Enum.count(embed_values) > 0 do
          true -> changeset
          _ -> add_error(changeset, embed_field, message_fn.())
        end

      _ ->
        changeset
    end
  end

  def validate_phone_number(changeset, field, country \\ nil) do
    case get_field(changeset, field) do
      v when v in [nil, ""] ->
        changeset

      v ->
        case valid_phone?(v, country) do
          true -> changeset
          _ -> add_error(changeset, field, "is invalid")
        end
    end
  end
end
