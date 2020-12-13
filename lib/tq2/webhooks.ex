defmodule Tq2.Webhooks do
  @moduledoc """
  The Webhooks context.
  """

  alias Tq2.Repo
  alias Tq2.Webhooks.MercadoPago

  @doc """
  Gets a single webhook.

  ## Examples

      iex> get_webhook("mercado_pago", 123)
      %MercadoPago{}

      iex> get_webhook("other", 456)
      nil

  """
  def get_webhook("mercado_pago", id) do
    MercadoPago |> Repo.get(id)
  end

  def get_webhook(_, _), do: nil

  @doc """
  Creates a webhook.

  ## Examples

      iex> create_webhook(%{field: "value"})
      {:ok, %Webhook{}}

      iex> create_webhook(%{field: "bad_value"})
      ** (RuntimeError) Invalid webhook
  """
  def create_webhook(%{name: "mercado_pago"} = attrs) do
    %MercadoPago{}
    |> MercadoPago.changeset(attrs)
    |> Repo.insert()
  end

  def create_webhook(_), do: raise("Invalid webhook")
end
