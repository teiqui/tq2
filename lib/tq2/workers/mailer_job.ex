defmodule Tq2.Workers.MailerJob do
  alias Tq2.Notifications.Mailer

  def perform(mail, opts \\ []) do
    Mailer.deliver_now!(mail, opts)
  end
end
