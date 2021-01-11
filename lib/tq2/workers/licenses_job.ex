defmodule Tq2.Workers.LicensesJob do
  alias Tq2.Accounts
  alias Tq2.Gateways.Stripe, as: StripeClient

  def perform("customer_id", id) do
    update_license!(customer_id: id)
  end

  def perform("subscription_id", id) do
    update_license!(subscription_id: id)
  end

  defp update_license!(get_by) do
    get_by
    |> Accounts.get_license!()
    |> StripeClient.update_license()
  rescue
    ex ->
      # TODO: Change to set_context when it's fixed
      # https://github.com/getsentry/sentry-elixir/issues/349
      Sentry.capture_exception(ex,
        stacktrace: __STACKTRACE__,
        extra: %{get_by: inspect(get_by)},
        tags: %{worker: __MODULE__}
      )

      raise ex
  end
end
