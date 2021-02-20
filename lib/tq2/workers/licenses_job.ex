defmodule Tq2.Workers.LicensesJob do
  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, License}
  alias Tq2.Gateways.Stripe, as: StripeClient

  import Tq2.Notifications, only: [send_license_expired: 1, send_license_near_to_expire: 1]

  def perform("customer_id", id) do
    update_license!(customer_id: id)
  end

  def perform("subscription_id", id) do
    update_license!(subscription_id: id)
  end

  def perform("notify_near_to_expire", id) do
    Accounts.get_license!(id: id)
    |> notify_near_to_expire()
  end

  def perform("lock", id) do
    Accounts.get_license!(id: id)
    |> lock_license()
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

  defp notify_near_to_expire(%{account: account, status: "trial"}) do
    account
    |> Accounts.get_owner()
    |> send_license_near_to_expire()
  end

  defp notify_near_to_expire(_license), do: nil

  defp lock_license(%{account: account, status: "trial"} = license) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:account, Account.changeset(account, %{status: "locked"}))
      |> Ecto.Multi.update(:license, License.changeset(license, %{status: "locked"}))
      |> Tq2.Repo.transaction()

    case result do
      {:ok, _} ->
        account
        |> Accounts.get_owner()
        |> send_license_expired()

      {:error, _operation, failed_value, changes} ->
        Sentry.capture_message(
          "[LicensesJob] Can't update license",
          extra: %{
            license_id: license.id,
            errors: inspect(failed_value.errors),
            attrs: inspect(changes)
          }
        )

        nil
    end
  end

  defp lock_license(_license), do: nil
end
