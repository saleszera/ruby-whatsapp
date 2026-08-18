# Sending Messages

Everything in this directory builds an *outbound* payload for
`POST /{PHONE_ID}/messages`. Each WhatsApp message kind is its own
`ActiveModel`-validated Ruby class, so a payload Meta would reject comes back as a
local `ActiveModel::ValidationError` instead of a round trip and an opaque
`#131009`.

Addresses **`phone_id`**, not `waba_id`, and needs the
`whatsapp_business_messaging` permission.

## The two ways to send

Every kind registered in `Whatsapp::Messages::KINDS` gets a generated
`Whatsapp::Messages.send_<kind>!` class method — pass the recipient and the
kind-specific fields as keyword arguments:

```ruby
Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hello!")
# => #<Whatsapp::Messages::Response messaging_product="whatsapp" ...>
```

If the kind is only known at runtime, drop down to the factory those methods are
built on:

```ruby
Whatsapp::Messages.new(
  kind: :text,                                    # or a variable; String or Symbol
  payload: { to: "+15551234567", body: "Hello!" },
  client: Whatsapp::Client.new                    # optional
).send!
```

Both forms accept an optional `client:` (defaults to a new `Whatsapp::Client`
built from `Whatsapp.configuration`) and return a
[`Whatsapp::Messages::Response`](#the-response).

## The kinds

| Kind | Method | Sends |
| --- | --- | --- |
| `:text` | [`send_text!`](text.md) | Plain text with an optional link preview |
| `:image` | [`send_image!`](image.md) | An image with an optional caption |
| `:video` | [`send_video!`](video.md) | A video with an optional caption |
| `:audio` | [`send_audio!`](audio.md) | A voice note or audio clip |
| `:document` | [`send_document!`](document.md) | A file with an optional caption and filename |
| `:sticker` | [`send_sticker!`](sticker.md) | A sticker |
| `:contacts` | [`send_contacts!`](contacts.md) | A rich, vCard-like contact card |
| `:reaction` | [`send_reaction!`](reaction.md) | An emoji reaction to a previous message |
| `:location` | [`send_location!`](location.md) | A latitude/longitude pin |
| `:address` | [`send_address!`](address.md) | A delivery-address form (India & Singapore only) |
| `:location_request` | [`send_location_request!`](location_request.md) | A prompt asking the user to share their location |
| `:template` | [`send_template!`](template.md) | A pre-approved marketing/utility/authentication template |
| `:interactive` | [`send_interactive!`](interactive.md) | Reply buttons, lists, CTA URLs, or carousels |

Plus one endpoint that isn't a message kind at all:

| | Method | Does |
| --- | --- | --- |
| — | [`mark_message_as_read!`](mark_message_as_read.md) | Closes the read-receipt loop on an inbound message |

## The shared envelope

Every kind except `mark_message_as_read` inherits `Messages::Base`, which supplies
`to` (the only universally required field, validated for presence) and wraps the
kind-specific hash in a common envelope:

```ruby
{
  messaging_product: "whatsapp",
  recipient_type: "individual",
  to: "+15551234567",
  type: "<kind>",
  "<kind>": { ... }        # the kind-specific payload
}
```

Three kinds break the `type == kind` symmetry because Meta transports them as
interactive messages: [`address`](address.md), [`location_request`](location_request.md),
and of course [`interactive`](interactive.md) all serialize with `type: "interactive"`.

## The response

A successful `send!` returns a `Whatsapp::Messages::Response`, deserialized from a
body shaped like:

```json
{
  "messaging_product": "whatsapp",
  "contacts": [{ "input": "+15551234567", "wa_id": "15551234567" }],
  "messages": [{ "id": "wamid.HBgLMTU1NTU1NTU1NTUV..." }]
}
```

```ruby
response = Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hi")

response.messaging_product     # => "whatsapp"
response.messages.first.id     # => "wamid.HBgLMTU1NTU1NTU1NTUV..."
response.contacts.first.input  # => "+15551234567"
response.contacts.first.wa_id  # => "15551234567"
response.success               # => nil for a normal send
```

`#success` is `nil` for a normal message send and `true`/`false` only for the
status-update endpoints that reply `{"success": true}` — today just
[`mark_message_as_read!`](mark_message_as_read.md).

## Errors

| Raised | When |
| --- | --- |
| `ArgumentError` | `to:` (or another required keyword) is missing |
| `ActiveModel::ValidationError` | A field fails a local validation |
| `Whatsapp::Messages::PayloadError` | `kind:` is unrecognized — only reachable through the `Messages.new(kind:, payload:)` form |
| `Whatsapp::RequestError` | The API answered with a non-2xx status |

Because every kind runs `validate!` at the end of its own `initialize`, an invalid
field raises at *construction* time, before a client is ever touched:

```ruby
Whatsapp::Messages.send_image!(to: "+15551234567")
# => ActiveModel::ValidationError: Either id or link must be present

Whatsapp::Messages.new(kind: :telepathy, payload: { to: "+1" })
# => Whatsapp::Messages::PayloadError: Unknown message kind: :telepathy.
#    Known kinds: text, image, audio, video, document, sticker, contacts,
#    reaction, location, address, location_request, template, interactive
```

See [../errors.md](../errors.md) for the full hierarchy.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/text-messages>
