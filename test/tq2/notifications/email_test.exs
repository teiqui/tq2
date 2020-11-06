defmodule Tq2.Notifications.EmailTest do
  use ExUnit.Case
  use Bamboo.Test

  alias Tq2.Accounts.User
  alias Tq2.Notifications.Email

  test "password reset email" do
    user = %User{name: "John", email: "some@email.com", password_reset_token: "test-token"}

    email = Email.password_reset(user)

    assert email.to == user.email
    assert email.html_body =~ user.password_reset_token
    assert email.text_body =~ user.password_reset_token
  end
end
