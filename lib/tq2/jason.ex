require Protocol

# TODO: remove when PaperTrail support _proper_ map serialization
Protocol.derive(Jason.Encoder, Money, only: [:amount, :currency])
Protocol.derive(Jason.Encoder, Tq2.Shops.Configuration)
Protocol.derive(Jason.Encoder, Tq2.Shops.Data)
Protocol.derive(Jason.Encoder, Tq2.Shops.Location)
Protocol.derive(Jason.Encoder, Ecto.Changeset, only: [:changes])
