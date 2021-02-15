defmodule Tq2Web.Utils do
  import Tq2Web.Gettext, only: [dgettext: 2]

  def invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end

  def localize_date(date) do
    {:ok, formatted} =
      date
      |> Timex.format(dgettext("times", "%m/%d/%y"), :strftime)

    formatted
  end

  def localize_datetime(date) do
    {:ok, formatted} =
      date
      |> Timex.format(dgettext("times", "%m/%d/%y %H:%M:%S"), :strftime)

    formatted
  end

  def format_money(%Money{} = money) do
    Money.to_string(money, symbol: true)
  end
end
