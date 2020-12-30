defmodule Tq2Web.Order.PaymentFormComponentTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Tq2Web.Order.PaymentFormComponent

  describe "render" do
    test "render form" do
      content = render_component(PaymentFormComponent, changeset: changeset())

      assert content =~ "Cash"
      assert content =~ "Wire transfer"
      assert content =~ "Other"
      assert content =~ "value=\"wire_transfer\"\nchecked"
      assert content =~ "value=\"10.00\""
    end
  end

  defp changeset do
    Tq2.Payments.change_payment(
      %Tq2.Transactions.Cart{
        account: %Tq2.Accounts.Account{country: "ar"},
        lines: [%Tq2.Transactions.Line{price: Money.new(1000, "ARS")}]
      },
      %{
        id: 1,
        kind: "wire_transfer",
        amount: Money.new(1000, "ARS")
      }
    )
  end
end
