defmodule Tq2Web.Order.PaymentFormComponent do
  use Tq2Web, :live_component

  defp payment_methods do
    [
      {"cash", dgettext("payments", "Cash")},
      {"wire_transfer", dgettext("payments", "Wire transfer")},
      {"other", dgettext("payments", "Other")}
    ]
  end

  defp payment_kind?(%{changes: %{kind: kind}}, kind), do: true
  defp payment_kind?(_, _kind), do: false

  defp submit_payment(%{valid?: true}) do
    dgettext("payments", "Create payment")
    |> submit(class: "btn btn-primary rounded-pill font-weight-bold py-2")
  end

  defp submit_payment(_), do: nil

  defp static_img(kind, text) do
    img_tag(
      Routes.static_path(Tq2Web.Endpoint, "/images/#{kind}.png"),
      alt: text,
      width: "20",
      height: "20",
      class: "img-fluid mr-3"
    )
  end
end
