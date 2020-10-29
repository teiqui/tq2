defmodule Tq2Web.InputHelpers do
  use Phoenix.HTML

  def input(form, field, label \\ nil, opts \\ []) do
    type = opts[:using] || guess_input_type(form, field, opts)
    wrapper_opts = [class: "form-group"]
    label_opts = opts[:label_html] || []
    input_opts = input_opts(type, form, field, opts)

    content_tag :div, wrapper_opts do
      label = label(form, field, label || humanize(field), label_opts)
      input = input_tag(type, form, field, input_opts)
      error = Tq2Web.ErrorHelpers.error_tag(form, field)

      [label, input, error || ""]
    end
  end

  defp guess_input_type(form, field, opts) do
    if is_list(opts[:collection]) || is_map(opts[:collection]) do
      :select
    else
      Phoenix.HTML.Form.input_type(form, field)
    end
  end

  defp input_opts(:select, form, field, opts) do
    input_opts(nil, form, field, opts)
    |> Keyword.put(:collection, opts[:collection] || [])
  end

  defp input_opts(_type, form, field, opts) do
    opts = opts[:input_html] || []
    {custom_class, opts} = Keyword.pop(opts, :class)

    class =
      ["form-control", custom_class, state_class(form, field)]
      |> Enum.filter(& &1)
      |> Enum.join(" ")

    Keyword.merge([class: class], opts)
  end

  defp state_class(form, field) do
    cond do
      form.errors[field] -> "is-invalid"
      true -> nil
    end
  end

  defp input_tag(:select = type, form, field, input_opts) do
    {options, input_opts} = Keyword.pop(input_opts, :collection)

    apply(Phoenix.HTML.Form, type, [form, field, options, input_opts])
  end

  defp input_tag(type, form, field, input_opts) do
    apply(Phoenix.HTML.Form, type, [form, field, input_opts])
  end
end
