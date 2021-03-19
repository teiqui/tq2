defmodule Tq2Web.Utils do
  import Tq2Web.Gettext, only: [dgettext: 2]

  alias Tq2.Accounts.Account

  def invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end

  def localize_date(date) do
    {:ok, formatted} =
      date
      |> Timex.format(dgettext("times", "%m/%d/%y"), :strftime)

    formatted
  end

  def localize_datetime(date, %Account{time_zone: time_zone}) do
    {:ok, formatted} =
      date
      |> Timex.to_datetime(time_zone)
      |> Timex.format(dgettext("times", "%m/%d/%y %H:%M:%S"), :strftime)

    formatted
  end

  def format_money(%Money{} = money) do
    Money.to_string(money, symbol: true)
  end
end
