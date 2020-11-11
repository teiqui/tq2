defmodule Tq2Web.LicenseView do
  use Tq2Web, :view
  use Scrivener.HTML

  @statuses %{
    dgettext("licenses", "Trial") => "trial",
    dgettext("licenses", "Active") => "active",
    dgettext("licenses", "Unpaid") => "unpaid",
    dgettext("licenses", "Locked") => "locked",
    dgettext("licenses", "Cancelled") => "cancelled"
  }

  def status(license) do
    statuses = invert(@statuses)

    statuses[license.status]
  end

  def localize(paid_until) do
    {:ok, formatted} = paid_until |> Timex.format(dgettext("times", "{M}/{D}/{YYYY}"))

    formatted
  end

  defp invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end
end
