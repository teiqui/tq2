defmodule Tq2.Notifications.Email do
  use Bamboo.Phoenix, view: Tq2Web.EmailView

  import Bamboo.Email
  import Tq2Web.Gettext

  alias Tq2.Accounts.User

  def password_reset(%User{} = user) do
    subject = dgettext("emails", "Password reset")

    base_email()
    |> to(user.email)
    |> subject(subject)
    |> render(:password_reset, user: user)
  end

  defp base_email() do
    new_email()
    |> from({gettext("Teiqui"), "support@teiqui.com"})
    |> put_layout({Tq2Web.LayoutView, :email})
  end
end
