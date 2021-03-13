defmodule Tq2.Gateways.Conekta do
  import Tq2Web.Gettext, only: [dgettext: 2, dgettext: 3]

  alias Tq2.Transactions.Cart

  @allowed_payment_methods ~w(cash card bank_transfer)
  @request_headers %{
    "Accept" => "application/vnd.conekta-v2.0.0+json",
    "Content-Type" => "application/json",
    "User-Agent" => "Teiqui Elixir SDK"
  }
  @test_email "juan.perez@conekta.com"
  @test_phone "5266982090"

  def countries do
    if Application.get_env(:tq2, :env) == :prod, do: [], else: ["mx"]
  end

  def commission_url, do: "https://conekta.com/pricing"

  def check_credentials(api_key) do
    api_key = api_key |> String.trim()

    attrs_for()
    |> request_post(%{data: %{api_key: api_key}}, :create_preference)
    |> parse_response()
    |> parse_credential_response()
  end

  def get_order(app, id) do
    id
    |> request_get(app, :get_order)
    |> parse_response()
  end

  def create_cart_preference(app, cart, store) do
    cart
    |> attrs_for(store)
    |> request_post(app, :create_preference)
    |> parse_response()
  end

  def create_partial_preference(app, payment, store) do
    payment
    |> attrs_for(store)
    |> request_post(app, :create_preference)
    |> parse_response()
  end

  def response_to_payment(%{"charges" => %{"data" => charges}}) do
    charge = charges |> Enum.find(&(&1["status"] == "paid"))
    external_id = charge["channel"]["checkout_request_id"]
    paid_at = charge["paid_at"] |> DateTime.from_unix!()

    %{
      external_id: external_id,
      paid_at: paid_at,
      status: "paid"
    }
  end

  def response_to_payment(_), do: %{}

  defp items_for_cart(%{data: %{handing: "delivery", shipping: %{price: price}}} = cart) do
    name = dgettext("stores", "Shipping") |> normalize_string()

    delivery = [
      %{
        name: name,
        unit_price: money_to_integer(price),
        quantity: 1
      }
    ]

    %{cart | data: %{}}
    |> items_for_cart()
    |> Kernel.++(delivery)
  end

  defp items_for_cart(cart) do
    cart.lines |> Enum.map(&to_conekta_item(&1, cart))
  end

  defp to_conekta_item(line, cart) do
    name = line.name |> normalize_string()
    price = cart |> Cart.line_total(%{line | quantity: 1}) |> money_to_integer()

    %{
      name: name,
      unit_price: price,
      quantity: 1
    }
  end

  defp pending_payment_items(%{amount: amount, cart: %{order: %{id: id}}}) do
    name =
      "payments"
      |> dgettext("Pending amount of order #%{id}", id: id)
      |> normalize_string()

    [
      %{
        name: name,
        quantity: 1,
        unit_price: money_to_integer(amount)
      }
    ]
  end

  defp money_to_integer(%Money{amount: amount}), do: amount

  defp normalize_string(value) do
    value
    |> String.normalize(:nfd)
    |> String.replace(~r/[^a-zA-Z0-9,\-\.\s]/u, "")
  end

  defp request_get(id, app, :get_order) do
    "/orders/#{id}"
    |> url()
    |> HTTPoison.get(headers(app))
  end

  defp request_post(attrs, app, :create_preference) do
    params = Jason.encode!(attrs)

    "/checkouts"
    |> url()
    |> HTTPoison.post(params, headers(app))
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> Jason.decode!()
  end

  defp parse_response({_, %HTTPoison.Response{body: body, status_code: code}}) do
    {_, body} = Jason.decode(body)

    Sentry.capture_message("Conekta Error", extra: %{body: body, status_code: code})

    body
  end

  defp url(path) do
    "https://api.conekta.io" <> path
  end

  defp auth_token(%{data: %{api_key: key}}) do
    "#{key}:"
    |> Base.encode64()
    |> String.trim()
  end

  defp headers(app) do
    @request_headers
    |> Map.put("Authorization", "Basic #{auth_token(app)}")
  end

  defp email_for_customer(%{email: email}) when is_binary(email), do: email
  defp email_for_customer(_customer), do: @test_email

  defp phone_for_customer(%{phone: phone}) when is_binary(phone) do
    phone = phone |> String.replace(~r(\D), "")

    case length(phone) do
      8 -> "52#{phone}"
      10 -> phone
      _ -> @test_phone
    end
  end

  defp phone_for_customer(_customer), do: @test_phone

  defp attrs_for do
    cart = %Tq2.Transactions.Cart{
      customer: %{name: "Test"},
      price_type: "regular",
      lines: [
        %Tq2.Transactions.Line{
          name: "Test item",
          price: %Money{amount: 10000, currency: "MXN"},
          quantity: 1
        }
      ]
    }

    cart |> attrs_for(%{name: "Test"})
  end

  defp attrs_for(%Cart{customer: customer} = cart, store) do
    expired_at =
      DateTime.utc_now()
      |> Timex.shift(weeks: 1)
      |> DateTime.to_unix(:second)

    %{
      name: normalize_string(store.name),
      type: "PaymentLink",
      recurrent: false,
      expired_at: expired_at,
      allowed_payment_methods: @allowed_payment_methods,
      needs_shipping_contact: false,
      order_template: %{
        line_items: items_for_cart(cart),
        currency: "MXN",
        customer_info: %{
          name: customer.name,
          email: email_for_customer(customer),
          phone: phone_for_customer(customer)
        }
      }
    }
  end

  defp attrs_for(%{cart: %{customer: customer}} = payment, store) do
    expired_at =
      DateTime.utc_now()
      |> Timex.shift(weeks: 1)
      |> DateTime.to_unix(:second)

    %{
      name: normalize_string(store.name),
      type: "PaymentLink",
      recurrent: false,
      expired_at: expired_at,
      allowed_payment_methods: @allowed_payment_methods,
      needs_shipping_contact: false,
      order_template: %{
        line_items: pending_payment_items(payment),
        currency: "MXN",
        customer_info: %{
          name: customer.name,
          email: email_for_customer(customer),
          phone: phone_for_customer(customer)
        }
      }
    }
  end

  defp parse_credential_response(%{"id" => _, "url" => _, "livemode" => true}), do: :ok

  defp parse_credential_response(%{"livemode" => false}) do
    {:error, dgettext("conekta", "Test credentials")}
  end

  defp parse_credential_response(%{"details" => [%{"message" => message}]}), do: {:error, message}

  defp parse_credential_response(_) do
    {:error, dgettext("conekta", "Invalid credentials")}
  end
end
