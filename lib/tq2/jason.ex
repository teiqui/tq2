require Protocol

# We must do this, just because Money does not
Protocol.derive(Jason.Encoder, Money, only: [:amount, :currency])
