defmodule Tq2Web.Order.PaymentComponentTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Tq2Web.Order.PaymentComponent

  describe "render" do
    test "render payment" do
      content =
        render_component(
          PaymentComponent,
          payment: payment(),
          socket: Tq2Web.Endpoint
        )

      assert content =~ "Cash"
      assert content =~ "10.00"
      assert content =~ "phx-click=\"delete\""
    end
  end

  defp payment do
    %Tq2.Payments.Payment{
      id: 1,
      kind: "cash",
      amount: Money.new(1000, "ARS")
    }
  end
end
