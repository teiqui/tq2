defmodule Tq2.Utils.TrimmedString do
  use Ecto.Type

  def type, do: :string

  def cast(nil), do: {:ok, nil}

  def cast(binary) when is_binary(binary), do: {:ok, String.trim(binary)}

  def cast(other), do: Ecto.Type.cast(:string, other)

  def load(data), do: Ecto.Type.load(:string, data)

  def dump(data), do: Ecto.Type.dump(:string, data)
end
