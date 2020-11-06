defmodule Tq2.Notifications do
  alias Tq2.Accounts.User
  alias Tq2.Notifications.{Mailer, Email}

  def send_password_reset(%User{} = user) do
    user
    |> Email.password_reset()
    |> Mailer.deliver_later()
  end
end
