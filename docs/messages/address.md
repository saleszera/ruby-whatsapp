# Address Messages

Collects or confirms a structured delivery address through a native WhatsApp form,
instead of parsing a free-text reply.

> **India and Singapore only.** This is a Meta feature-availability restriction on the
> WhatsApp Business Account itself, not merely a payload field. A WABA outside those
> two markets gets `(#131009) Unsupported Interactive Message type` — that is expected,
> not a bug in this class.

```ruby
Whatsapp::Messages.send_address!(
  to: "+15551234567",
  body: "Please share your delivery address",
  country: "IN"
)
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `body` | yes | The prompt shown above the form |
| `country` | yes | `"IN"` or `"SG"` only |
| `footer` | no | Small print under the form |
| `values` | no | Hash pre-filling form fields |
| `saved_addresses` | no | Array of previously saved addresses to offer. Defaults to `[]` |

`values` pre-fills the form so the customer edits rather than types. `saved_addresses`
offers a pick list of addresses you already hold for them:

```ruby
Whatsapp::Messages.send_address!(
  to: "+15551234567",
  body: "Please share your delivery address",
  country: "IN",
  footer: "Thanks for shopping with us",
  values: { name: "Jane Doe", phone_number: "+15550001111", city: "Bangalore" },
  saved_addresses: [
    { id: "addr_1", name: "Jane Doe", pin_code: "560001",
      address: "12 MG Road", city: "Bangalore", state: "KA" },
  ]
)
```

## Serialized payload

Like [Location Request](location_request.md), this travels as an interactive message:

```ruby
Whatsapp::Messages::Address.new(
  to: "+15551234567",
  body: "Please share your delivery address",
  country: "IN",
  footer: "Thanks for shopping with us",
  values: { name: "Jane Doe", city: "Bangalore" }
).serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567",
#   type: "interactive",
#   interactive: {
#     type: "address_message",
#     body: { text: "Please share your delivery address" },
#     action: {
#       name: "address_message",
#       parameters: { country: "IN", values: { name: "Jane Doe", city: "Bangalore" } }
#     },
#     footer: { text: "Thanks for shopping with us" }
#   }
# }
```

`values` is included only when given; `saved_addresses` only when non-empty; `footer`
only when truthy.

## Validation errors

```ruby
Whatsapp::Messages.send_address!(to: "+15551234567", body: "Address?", country: "US")
# => ActiveModel::ValidationError: Country is not included in the list
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/address-messages>
