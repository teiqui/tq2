defmodule Tq2Web.Store.ButtonComponent do
  use Tq2Web, :live_component

  alias Tq2Web.Store.{OptionsComponent, ShareComponent}

  defp show_button?(%{lines: []}), do: false
  defp show_button?(_), do: true

  defp button_wrapper(%{to: to, enabled: enabled}, do: block) do
    live_redirect(to: to, class: link_button_classes(enabled), do: block)
  end

  defp button_wrapper(%{enabled: enabled, disable_with: disable_with}, do: block) do
    submit(
      [
        class: link_button_classes(true),
        phx_disable_with: disable_with,
        disabled: !enabled
      ],
      do: block
    )
  end

  defp link_button_classes(true) do
    "btn btn-block btn-lg btn-primary"
  end

  defp link_button_classes(_) do
    "btn btn-block btn-lg btn-primary disabled"
  end
end
