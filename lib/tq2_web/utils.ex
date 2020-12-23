defmodule Tq2Web.Utils do
  import Tq2Web.Gettext, only: [dgettext: 2]

  def invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end

  def localize_date(date) do
    {:ok, formatted} =
      date
      |> Timex.format(dgettext("times", "{M}/{D}/{YYYY}"))

    formatted
  end

  def localize_datetime(date) do
    {:ok, formatted} =
      date
      |> Timex.format(dgettext("times", "{M}/{D}/{YYYY} {h24}:{m}:{s}"))

    formatted
  end
end
