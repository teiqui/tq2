defmodule Tq2Web.InputHelpers do
  use Phoenix.HTML

  import Tq2Web.Gettext

  def input(form, field, label \\ nil, opts \\ []) do
    type = opts[:using] || guess_input_type(form, field, opts)
    label_opts = label_opts(type, opts)
    input_opts = input_opts(type, form, field, opts)

    content_tag :div, wrapper_opts(opts) do
      label =
        if label == false do
          ""
        else
          label(form, field, label || humanize(field), label_opts)
        end

      error = Tq2Web.ErrorHelpers.error_tag(form, field)

      input = input_tag(type, form, field, input_opts ++ [with_errors: !!error])

      group(type, label, input, error || "")
    end
  end

  def radio_input(form, field, value, opts \\ [], do: block) do
    content_tag(:div, class: "custom-control custom-radio #{opts[:container_class]}") do
      input_opts = [class: "custom-control-input #{opts[:input_class]}"]
      input = radio_button(form, field, value, input_opts)

      label =
        label(for: input_id(form, field, value), class: "custom-control-label") do
          block
        end

      [input, label]
    end
  end

  defp group(:checkbox, label, [input | hint], error) do
    content_tag :div, class: "custom-control custom-switch" do
      [input, label, hint, error]
    end
  end

  defp group(:checkbox, label, input, error) do
    content_tag :div, class: "custom-control custom-switch" do
      [input, label, error]
    end
  end

  defp group(:file_input, label, input, error) do
    content_tag :div, class: "custom-file" do
      [input, label, error]
    end
  end

  defp group(_type, label, input, error) do
    [label, input, error]
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

  defp label_opts(:checkbox, opts) do
    label_opts(opts, "custom-control-label")
  end

  defp label_opts(:file_input, opts) do
    opts = Keyword.merge([data_browse: dgettext("files", "Browse")], opts[:label_html] || [])

    label_opts([label_html: opts], "custom-file-label")
  end

  defp label_opts(_type, opts) when is_list(opts) do
    opts[:label_html] || []
  end

  defp label_opts(opts, main_class) when is_binary(main_class) do
    opts = opts[:label_html] || []
    {custom_class, opts} = Keyword.pop(opts, :class)

    class =
      [main_class, custom_class]
      |> Enum.filter(& &1)
      |> Enum.join(" ")

    Keyword.merge([class: class], opts)
  end

  defp input_opts(:select, form, field, opts) do
    input_opts(nil, form, field, opts)
    |> Keyword.put(:collection, opts[:collection] || [])
  end

  defp input_opts(:file_input, form, field, opts) do
    input_opts(form, field, opts, "custom-file-input")
  end

  defp input_opts(:checkbox, form, field, opts) do
    input_opts(form, field, opts, "custom-control-input")
  end

  defp input_opts(type, form, field, opts) when is_atom(type) do
    input_opts(form, field, opts, "form-control")
  end

  defp input_opts(form, field, opts, main_class) do
    opts = opts[:input_html] || []
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

  defp input_tag(:checkbox = type, form, field, input_opts) do
    Phoenix.HTML.Form
    |> apply(type, [form, field, input_opts])
    |> input_with_hint(input_opts)
  end

  defp input_tag(type, form, field, input_opts) do
    case input_opts[:prepend] do
      nil ->
        Phoenix.HTML.Form
        |> apply(type, [form, field, input_opts])
        |> input_with_hint(input_opts)

      _prepend ->
        input_with_prepend(type, form, field, input_opts)
    end
  end

  defp input_with_prepend(type, form, field, input_opts) do
    invalid_class = if input_opts[:with_errors], do: "is-invalid"

    input_group =
      content_tag(:div, class: "input-group #{invalid_class}") do
        prepend_group =
          content_tag(:div, class: "input-group-prepend") do
            content_tag(:span, input_opts[:prepend], class: "input-group-text")
          end

        input = apply(Phoenix.HTML.Form, type, [form, field, input_opts])

        [prepend_group, input]
      end

    input_group |> input_with_hint(input_opts)
  end

  defp hint_tag(text) do
    content_tag(:small, text, class: "form-text text-muted")
  end

  defp input_with_hint(input, input_opts) do
    case input_opts[:hint] do
      nil -> input
      text -> [input, hint_tag(text)]
    end
  end
end
