defmodule Tq2.Support.MercadoPagoHelper do
  alias Tq2.Gateways.MercadoPago, as: MPClient

  defmacro mock_check_credentials(value \\ [], do: block) do
    quote do
      import Mock

      with_mock MPClient, check_credentials: fn _credential -> unquote(value) end do
        unquote(block)
      end
    end
  end
end
