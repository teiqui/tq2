defmodule Tq2Web.LayoutView do
  use Tq2Web, :view

  def locale do
    Tq2Web.Gettext
    |> Gettext.get_locale()
    |> String.replace(~r/_\w+/, "")
  end
end
