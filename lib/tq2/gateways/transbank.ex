defmodule Tq2.Gateways.Transbank do
  import Tq2Web.Gettext, only: [dgettext: 2]
  import Tq2.Utils.Urls, only: [store_uri: 0]

  alias Tq2.Transactions.Cart

  @paths %{
    confirm_preference:
      "/ewallet-plugin-api-services/services/transactionservice/gettransactionnumber",
    create_transaction: "/ewallet-plugin-api-services/services/transactionservice/sendtransaction"
  }
  @request_headers %{
    "Accept" => "application/json",
    "Content-Type" => "application/json"
  }
  @signature_params %{
    confirm_preference: [
      :occ,
      :externalUniqueNumber,
      :issuedAt
    ],
    create_transaction: [
      :externalUniqueNumber,
      :total,
      :itemsQuantity,
      :issuedAt,
      :callbackUrl
    ]
  }

  def countries, do: ["cl"]

  def commission_url do
    "https://portaltransbank.cl/afiliacion/resources/libs/nueva-oferta-presencial/#seccion-simulador"
  end

  def check_credentials(api_key, shared_secret) do
    app = %{data: %{api_key: api_key, shared_secret: shared_secret}}

    item = %{
      description: "test",
      quantity: 1,
      amount: 100
    }

    attrs = %{
      apiKey: app.data.api_key,
      appKey: app_key(),
      callbackUrl: callback_url("fake"),
      channel: "WEB",
      externalUniqueNumber: "#{__MODULE__.timestamp()}",
      issuedAt: __MODULE__.timestamp(),
      items: [item],
      itemsQuantity: 1,
      total: 100
    }

    signature = :create_transaction |> sign(attrs, app)
    attrs = attrs |> Map.put(:signature, signature)

    :create_transaction
    |> request_post(attrs)
    |> parse_response()
    |> check_result()
  end

  def create_cart_preference(app, cart, store, channel \\ "WEB") do
    total = cart |> Cart.total() |> money_to_integer()

    attrs = %{
      apiKey: app.data.api_key,
      appKey: app_key(),
      callbackUrl: callback_url(store),
      channel: channel,
      externalUniqueNumber: cart_external_reference(cart),
      generateOttQrCode: "true",
      issuedAt: __MODULE__.timestamp(),
      items: items_for_cart(cart),
      itemsQuantity: items_quantity(cart),
      total: total,
      widthHeight: 200
    }

    signature = :create_transaction |> sign(attrs, app)
    attrs = attrs |> Map.put(:signature, signature)

    :create_transaction
    |> request_post(attrs)
    |> parse_response()
  end

  def confirm_preference(app, %{
        gateway_data: %{"occ" => occ, "externalUniqueNumber" => external_id}
      }) do
    attrs = %{
      apiKey: app.data.api_key,
      appKey: app_key(),
      externalUniqueNumber: external_id,
      issuedAt: __MODULE__.timestamp(),
      occ: occ
    }

    signature = :confirm_preference |> sign(attrs, app)
    attrs = Map.put(attrs, :signature, signature)

    :confirm_preference
    |> request_post(attrs)
    |> parse_response()
  end

  @doc "Returns a parsed payment map given a MP-payment"
  def response_to_payment(
        %{
          "responseCode" => "OK",
          "result" => %{
            "issuedAt" => issued_at
          }
        },
        %{external_id: external_id}
      ) do
    paid_at = issued_at |> DateTime.from_unix!()

    %{
      external_id: external_id,
      paid_at: paid_at,
      status: "paid"
    }
  end

  def response_to_payment(
        %{"responseCode" => "INVALID_TRANSACTION", "description" => description},
        %{external_id: external_id}
      ) do
    %{
      external_id: external_id,
      status: "cancelled",
      error: description
    }
  end

  def response_to_payment(%{"description" => description}, _payment), do: %{error: description}

  # Public function to skip the System module mock
  def timestamp, do: System.os_time(:second)

  defp items_for_cart(%{data: %{handing: "delivery", shipping: %{price: price}}} = cart) do
    title = dgettext("stores", "Shipping") |> normalize_string()

    delivery = [
      %{
        description: title,
        quantity: 1,
        amount: money_to_integer(price),
        additionalData: nil,
        expire: -1
      }
    ]

    %{cart | data: %{}}
    |> items_for_cart()
    |> Kernel.++(delivery)
  end

  defp items_for_cart(cart) do
    Enum.map(cart.lines, &to_transbank_item(&1, cart))
  end

  defp to_transbank_item(line, cart) do
    name = line.name |> normalize_string()
    price = cart |> Cart.line_total(%{line | quantity: 1}) |> money_to_integer()

    %{
      description: name,
      quantity: line.quantity,
      amount: price,
      additionalData: nil,
      expire: -1
    }
  end

  # CLP never has decimals
  defp money_to_integer(%Money{amount: amount}), do: amount

  defp normalize_string(value) do
    value
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-zA-Z0-9#-_\s]/u, "")
  end

  defp cart_external_reference(%{id: id}) do
    "tq2-tb-cart-#{id}-#{__MODULE__.timestamp()}"
  end

  defp callback_url(store) do
    store_uri() |> Tq2Web.Router.Helpers.payment_check_url(:index, store)
  end

  defp sign(action, attrs, %{data: %{shared_secret: key}}) do
    to_io =
      @signature_params[action]
      |> Enum.map(fn key ->
        value = attrs[key]
        length = value |> to_string() |> String.length()

        "#{length}#{value}"
      end)
      |> Enum.join("")

    :sha256
    |> :crypto.hmac(key, to_io)
    |> Base.encode64()
    |> String.trim()
  end

  defp request_post(action, attrs) do
    url = url(action)
    params = Jason.encode!(attrs)

    HTTPoison.post(url, params, @request_headers)
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> Jason.decode!()
  end

  defp parse_response({_, %HTTPoison.Response{body: body, status_code: code}}) do
    {_, body} = Jason.decode(body)

    Sentry.capture_message("Transbank Error", extra: %{body: body, status_code: code})

    %{
      "description" => dgettext("stores", "Invalid transaction"),
      "responseCode" => "INVALID_TRANSACTION"
    }
  end

  defp items_quantity(%{data: %{handing: "delivery", shipping: %{price: _}}, lines: lines}) do
    Enum.count(lines) + 1
  end

  defp items_quantity(%{lines: lines}), do: Enum.count(lines)

  defp url(action) do
    domain =
      if Application.get_env(:tq2, :env) == :prod do
        "https://www.onepay.cl"
      else
        "https://onepay.ionix.cl"
      end

    domain <> @paths[action]
  end

  defp app_key do
    # Ruby app_key
    if Application.get_env(:tq2, :env) == :prod do
      "152C392E-F77C-426A-8667-55BEBB00EF1A"
    else
      "760272c4-9950-4bf3-be16-a6729800231a"
    end
  end

  defp check_result(%{"responseCode" => "OK"}), do: :ok

  defp check_result(%{"responseCode" => "COMMERCE_NOT_FOUND", "description" => msg}) do
    {:error, :api_key, msg}
  end

  defp check_result(%{"responseCode" => "INVALID_TRANSACTION_SIGN", "description" => msg}) do
    {:error, :shared_secret, msg}
  end

  defp check_result(%{"description" => msg}), do: {:error, :api_key, msg}
end
