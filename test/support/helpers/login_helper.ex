defmodule Tq2.Support.LoginHelper do
  use ExUnit.CaseTemplate

  import Plug.Conn

  alias Tq2.Accounts.{Account, Membership, Session, User}

  using do
    quote do
      import Tq2.Support.LoginHelper

      setup %{conn: conn} = config do
        do_setup(conn, config[:login_as], config[:login_role] || "owner")
      end
    end
  end

  def do_setup(_conn, nil, _role), do: :ok

  def do_setup(conn, email, role) do
    account = Tq2.Repo.get_by!(Account, name: "test_account")
    membership = %Membership{account_id: account.id}
    user = %User{email: email, role: role, memberships: [membership]}
    session = %Session{account: account, user: user}
    conn = assign(conn, :current_session, session)

    {:ok, conn: conn, account: account, user: user}
  end
end
