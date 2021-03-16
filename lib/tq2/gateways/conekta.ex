defmodule Tq2.Gateways.Conekta do
  import Tq2Web.Gettext, only: [dgettext: 2, dgettext: 3]
  import Tq2.Utils.Urls, only: [store_uri: 0]

  alias Tq2.Transactions.Cart

  @allowed_payment_methods ~w(cash card bank_transfer)
  @request_headers %{
    "Accept" => "application/vnd.conekta-v2.0.0+json",
    "Content-Type" => "application/json",
    "User-Agent" => "Teiqui Elixir SDK"
  }
  @test_email "juan.perez@conekta.com"
  @test_phone "5266982090"

  def countries, do: ["mx"]

  def commission_url, do: "https://conekta.com/pricing"

  def check_credentials(api_key) do
    app = %{data: %{api_key: String.trim(api_key)}}

    app
    |> customer_test()
    |> parse_customer_response()
  end

  def get_order(app, id) do
    id
    |> request_get(app, :get_order)
    |> parse_response()
  end

  def create_cart_preference(app, cart, store) do
    app
    |> create_customer(cart)
    |> attrs_for(cart, store)
    |> request_post(app, :create_preference)
    |> parse_response()
  end

  def response_to_payment(%{"charges" => %{"data" => charges}, "id" => id}) do
    charge = charges |> Enum.find(&(&1["status"] == "paid"))
    paid_at = charge["paid_at"] |> DateTime.from_unix!()

    %{
      external_id: id,
      paid_at: paid_at,
      status: "paid"
    }
  end

  def response_to_payment(_), do: %{}

  defp items_for(%Cart{order: %{id: id}} = cart) when is_integer(id) do
    name =
      "payments"
      |> dgettext("Pending amount of order #%{id}", id: id)
      |> normalize_string()

    amount =
      cart
      |> Cart.pending_amount()
      |> money_to_integer()

    [
      %{
        name: name,
        quantity: 1,
        unit_price: amount
      }
    ]
  end

  defp items_for(%Cart{data: %{handing: "delivery", shipping: %{price: price}}} = cart) do
    name = dgettext("stores", "Shipping") |> normalize_string()

    delivery = [
      %{
        name: name,
        unit_price: money_to_integer(price),
        quantity: 1
      }
    ]

    %{cart | data: %{}}
    |> items_for()
    |> Kernel.++(delivery)
  end

  defp items_for(%Cart{} = cart) do
    cart.lines |> Enum.map(&to_conekta_item(&1, cart))
  end

  defp to_conekta_item(line, cart) do
    name = line.name |> normalize_string()
    price = cart |> Cart.line_total(%{line | quantity: 1}) |> money_to_integer()

    %{
      name: name,
      unit_price: price,
      quantity: line.quantity
    }
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

    "/orders"
    |> url()
    |> HTTPoison.post(params, headers(app))
  end

  defp request_post(attrs, app, :create_customer) do
    params = Jason.encode!(attrs)

    "/customers"
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

    case String.length(phone) do
      8 -> "52#{phone}"
      10 -> phone
      _ -> @test_phone
    end
  end

  defp phone_for_customer(_customer), do: @test_phone

  defp attrs_for(customer_info, cart, store) do
    expires_at =
      DateTime.utc_now()
      |> Timex.shift(weeks: 1)
      |> DateTime.to_unix(:second)

    check_payment_url = cart |> check_payment_url(store)
    items = cart |> items_for()

    %{
      currency: "MXN",
      customer_info: customer_info,
      line_items: items,
      checkout: %{
        name: normalize_string(store.name),
        type: "HostedPayment",
        allowed_payment_methods: @allowed_payment_methods,
        expires_at: expires_at,
        is_redirect_on_failure: true,
        monthly_installments_enabled: false,
        monthly_installments_options: [],
        needs_shipping_contact: false,
        on_demand_enabled: false,
        success_url: check_payment_url,
        failure_url: check_payment_url
      }
    }
  end

  defp customer_test(app) do
    %{
      name: "Test",
      email: email_for_customer(%{}),
      phone: phone_for_customer(%{})
    }
    |> request_post(app, :create_customer)
    |> parse_response()
  end

  defp create_customer(app, %{customer: customer}) do
    %{
      name: customer.name,
      email: email_for_customer(customer),
      phone: phone_for_customer(customer)
    }
    |> request_post(app, :create_customer)
    |> parse_response()
    |> build_customer_info()
  end

  defp build_customer_info(%{"id" => id, "livemode" => true}), do: %{customer_id: id}

  defp build_customer_info(response) do
    Sentry.capture_message("Conekta Customer Error", extra: %{customer: response})

    response
  end

  defp check_payment_url(%Cart{order: %{id: _} = order}, store) do
    # Conekta doesn't support port
    %{store_uri() | port: nil} |> Tq2Web.Router.Helpers.order_url(:index, store, order)
  end

  defp check_payment_url(_cart, store) do
    # Conekta doesn't support port
    %{store_uri() | port: nil} |> Tq2Web.Router.Helpers.payment_check_url(:index, store)
  end

  defp parse_customer_response(%{"id" => _, "livemode" => true}), do: :ok

  defp parse_customer_response(%{"livemode" => false}) do
    {:error, dgettext("conekta", "Test credentials")}
  end

  defp parse_customer_response(%{"details" => [%{"message" => message}]}) do
    {:error, message}
  end

  defp parse_customer_response(_) do
    {:error, dgettext("conekta", "Invalid credentials")}
  end
end
