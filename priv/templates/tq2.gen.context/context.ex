defmodule <%= inspect context.module %> do
  @moduledoc """
  The <%= context.name %> context.
  """

  import Ecto.Query, warn: false

  alias <%= inspect schema.repo %>
  alias <%= inspect context.base_module %>.Trail
  alias <%= inspect context.base_module %>.Accounts.{Account, Session}
end
