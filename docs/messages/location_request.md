# Location Request Messages

Asks the user to **share their current location back to the business** — the inverse
of [Location](location.md). Useful for coordinating a delivery or a pickup without
making the customer type an address.

```ruby
Whatsapp::Messages.send_location_request!(
  to: "+15551234567",
  body: "Can you share your delivery location?"
)
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `body` | yes | The prompt text, max **1024** characters |

## Serialized payload

Despite being its own Ruby class, this travels as an interactive message on the wire
(`type: "interactive"`, `interactive.type: "location_request_message"`):

```ruby
Whatsapp::Messages::LocationRequest.new(
  to: "+15551234567", body: "Can you share your delivery location?"
).serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567",
#   type: "interactive",
#   interactive: {
#     type: "location_request_message",
#     body: "Can you share your delivery location?",
#     action: { name: "send_location" }
#   }
# }
```

> **Known bug — confirmed broken against the live API.** `body` is serialized as a
> bare String, but Meta's JSON schema requires `interactive.body` to be an object
> (`{ text: ... }`) or null. [`Address`](address.md) and
> [`Interactive`](interactive.md) both wrap body text correctly; this class does not,
> and live testing returns a schema rejection. Not yet fixed — track it before
> relying on this kind in production.

## The reply

The user's shared location arrives as an inbound webhook notification, deserialized
into `Whatsapp::Webhook::Message::Location` with `latitude`, `longitude`, `name`, and
`address`. See [../webhooks/messages.md](../webhooks/messages.md).

## Validation errors

```ruby
Whatsapp::Messages.send_location_request!(to: "+15551234567", body: "")
# => ActiveModel::ValidationError: Body can't be blank
```
