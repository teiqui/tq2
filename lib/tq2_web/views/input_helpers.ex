defmodule Tq2Web.InputHelpers do
  use Phoenix.HTML

  def input(form, field, label \\ nil, opts \\ []) do
    type = opts[:using] || guess_input_type(form, field, opts)
    label_opts = opts[:label_html] || []
    input_opts = input_opts(type, form, field, opts)

    content_tag :div, wrapper_opts(opts) do
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
      Phoenix.HTML.Form.input_type(form, field, %{
        "email" => :email_input,
        "file" => :file_input,
        "image" => :file_input,
        "logo" => :file_input,
        "password" => :password_input,
        "search" => :search_input,
        "url" => :url_input
      })
    end
  end

  defp wrapper_opts(opts) do
    opts = opts[:wrapper_html] || []
    {custom_class, opts} = Keyword.pop(opts, :class)

    class =
      ["form-group", custom_class]
      |> Enum.filter(& &1)
      |> Enum.join(" ")

    Keyword.merge([class: class], opts)
  end

  defp input_opts(:select, form, field, opts) do
    input_opts(nil, form, field, opts)
    |> Keyword.put(:collection, opts[:collection] || [])
  end

  defp input_opts(type, form, field, opts) do
    opts = opts[:input_html] || []
    main_class = if type == :file_input, do: "form-control-file", else: "form-control"
    {custom_class, opts} = Keyword.pop(opts, :class)

    class =
      [main_class, custom_class, state_class(form, field)]
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
