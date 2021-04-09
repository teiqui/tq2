defmodule Tq2.Workers.MailerJobTest do
  use Tq2.DataCase
  use Bamboo.Test

  import Tq2.Fixtures, only: [user_fixture: 1]

  alias Tq2.Notifications.Email
  alias Tq2.Workers.MailerJob

  describe "mailer job" do
    test "perform with license expired email" do
      user = user_fixture(nil)

      email = Email.license_expired(user)

      MailerJob.perform(email)

      assert_delivered_email(email)
    end
  end
end
