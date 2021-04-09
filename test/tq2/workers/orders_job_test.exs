defmodule Tq2.Workers.OrdersJobTest do
  use Tq2.DataCase
  use Bamboo.Test

  import Tq2.Fixtures, only: [create_order: 0]

  alias Tq2.Notifications.Email
  alias Tq2.Workers.OrdersJob

  describe "orders" do
    test "perform/1 should change cart to regular price" do
      %{order: order} = create_order()

      assert order.cart.price_type == "promotional"

      OrdersJob.perform(order.id)

      order = Tq2.Repo.preload(order, [cart: :lines], force: true)

      assert order.cart.price_type == "regular"
      assert_delivered_email(Email.expired_promotion(order))
    end
  end
end
