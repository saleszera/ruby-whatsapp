# `messages`

Inbound customer messages and outbound delivery statuses — the field you will spend
almost all your time on, and the only one with a Meta-published JSON schema.

`Whatsapp::Webhook::Messages`

## A full notification

```json
{
  "object": "whatsapp_business_account",
  "entry": [{
    "id": "102290129340398",
    "changes": [{
      "field": "messages",
      "value": {
        "messaging_product": "whatsapp",
        "metadata": { "display_phone_number": "15550783881", "phone_number_id": "106540352242922" },
        "contacts": [{ "profile": { "name": "Sheena Nelson" }, "wa_id": "16505551234" }],
        "messages": [{
          "from": "16505551234",
          "id": "wamid.HBg...",
          "timestamp": "1749416383",
          "type": "text",
          "text": { "body": "Does it come in another color?" }
        }]
      }
    }]
  }]
}
```

```ruby
value = notification.entry.first.changes.first.value

value.messaging_product           # => "whatsapp"
value.metadata.phone_number_id    # => "106540352242922"
value.metadata.display_phone_number # => "15550783881"
value.contacts.first.profile_name # => "Sheena Nelson"
value.contacts.first.wa_id        # => "16505551234"
value.messages.first.body         # => "Does it come in another color?"
value.statuses                    # => []
```

## Value accessors

| Accessor | Type |
| --- | --- |
| `messaging_product` | `"whatsapp"` |
| `metadata` | `Metadata` — `display_phone_number`, `phone_number_id` |
| `contacts` | `Array<Contact>` — `profile_name`, `wa_id` |
| `messages` | `Array<Message::*>` |
| `statuses` | `Array<Status>` |

A given notification carries **either** `messages` **or** `statuses`, never both — but
both accessors always return an array, so you can iterate either without a nil check.

> `contacts` here is the value-level sender identity (who wrote to you). It is a
> different thing from [`Message::Contacts`](#contacts) below, which is a contact
> *card* someone shared with you.

---

## Message types

Every entry in `messages` is dispatched by its `type` through the frozen
`Message::MESSAGE_TYPES` registry. An unrecognized type falls back to
[`Unknown`](#unknown), never an exception.

All message classes share this envelope from `Message::Base`:

| Accessor | Meaning |
| --- | --- |
| `from` | The customer's WhatsApp ID |
| `id` | The WAMID — pass it to [`mark_message_as_read!`](../messages/mark_message_as_read.md) |
| `timestamp` | Unix seconds, as a String |
| `type` | `"text"`, `"image"`, … |
| `context` | [`Context`](#context) or `nil` — set when replying or forwarding |
| `referral` | [`Referral`](#referral) or `nil` — set when the chat started from an ad |

### Text

```json
{ "type": "text", "text": { "body": "Does it come in another color?" } }
```

```ruby
message.body   # => "Does it come in another color?"
```

### Media — image, video, audio, document, sticker

All five share a `Media` superclass:

| Accessor | Meaning |
| --- | --- |
| `media_id` | Pass to [`Media#get_url`](../media/README.md) to download it |
| `mime_type` | `"image/jpeg"`, `"application/pdf"`, … |
| `sha256` | Content hash |
| `caption` | Present on image, video, document |

Plus one extra each on three of them:

| Type | Extra |
| --- | --- |
| `audio` | `voice` — `true` for a recorded voice note, `false` for an audio file |
| `document` | `filename` |
| `sticker` | `animated` |

```json
{ "type": "document",
  "document": { "id": "med.4", "mime_type": "application/pdf",
                "sha256": "abc", "caption": "Invoice", "filename": "invoice.pdf" } }
```

```ruby
message.media_id  # => "med.4"
message.mime_type # => "application/pdf"
message.filename  # => "invoice.pdf"

# fetch the bytes
info = Whatsapp::Media.new.get_url(media_id: message.media_id)
Whatsapp::Media.new.download(url: info["url"], save_to: message.filename)
```

```json
{ "type": "audio", "audio": { "id": "med.3", "mime_type": "audio/ogg", "sha256": "abc", "voice": true } }
```

```ruby
message.voice     # => true
```

### Location

```json
{ "type": "location",
  "location": { "latitude": 37.4847, "longitude": -122.1477,
                "name": "Meta HQ", "address": "1 Hacker Way" } }
```

```ruby
message.latitude   # => 37.4847
message.longitude  # => -122.1477
message.name       # => "Meta HQ"
message.address    # => "1 Hacker Way"
```

This is what comes back from a
[location request](../messages/location_request.md).

### Contacts

A contact *card* the customer shared with you.

```json
{ "type": "contacts",
  "contacts": [{ "name": { "formatted_name": "Jane Doe" },
                 "phones": [{ "phone": "+1", "type": "WORK" }] }] }
```

```ruby
card = message.contacts.first
card.name.formatted_name  # => "Jane Doe"
card.phones.first.phone   # => "+1"
```

Nested objects mirror the outbound [contacts message](../messages/contacts.md)
field-for-field: `Name`, `Phone`, `Email`, `Address`, `Org`, `Url`, plus `birthday`.

### Interactive

A tap on [reply buttons or a list](../messages/interactive.md).

```json
{ "type": "interactive",
  "interactive": { "type": "button_reply",
                   "button_reply": { "id": "confirm", "title": "Confirm" } } }
```

```ruby
message.interactive_type  # => "button_reply"  (or "list_reply")
message.reply_id          # => "confirm"       — the id you set when sending
message.title             # => "Confirm"
message.description       # => nil             — list_reply only
```

```json
{ "type": "interactive",
  "interactive": { "type": "list_reply",
                   "list_reply": { "id": "espresso", "title": "Espresso",
                                   "description": "Strong & short" } } }
```

```ruby
message.interactive_type  # => "list_reply"
message.reply_id          # => "espresso"
message.description       # => "Strong & short"
```

### Button

A tap on a **template** quick-reply button — distinct from `interactive` above, which
covers interactive messages.

```json
{ "type": "button", "button": { "text": "Confirm", "payload": "CONFIRM_PAYLOAD" } }
```

```ruby
message.text     # => "Confirm"
message.payload  # => "CONFIRM_PAYLOAD"
```

### Order

A cart submitted from your Meta catalog.

```json
{ "type": "order",
  "order": { "catalog_id": "cat.1", "text": "Here's my order",
             "product_items": [{ "product_retailer_id": "sku.1", "quantity": 2,
                                 "item_price": 9.99, "currency": "USD" }] } }
```

```ruby
message.catalog_id                       # => "cat.1"
message.text                             # => "Here's my order"
item = message.product_items.first
item.product_retailer_id                 # => "sku.1"
item.quantity                            # => 2
item.item_price                          # => 9.99
item.currency                            # => "USD"
```

### System

A change to the customer's account — a new phone number, an identity change.

```json
{ "type": "system",
  "system": { "body": "Jane changed to a new phone", "identity": "ABCD1234",
              "wa_id": "16505551234", "type": "customer_changed_number" } }
```

```ruby
message.body         # => "Jane changed to a new phone"
message.identity     # => "ABCD1234"
message.wa_id        # => "16505551234"
message.change_type  # => "customer_changed_number"
```

Note `change_type`, not `type` — `type` is taken by the message envelope.

### Reaction

```json
{ "type": "reaction", "reaction": { "message_id": "wamid.OLD", "emoji": "👍" } }
```

```ruby
message.message_id  # => "wamid.OLD"  — the message being reacted to
message.emoji       # => "👍"          — empty String when a reaction is removed
```

### Unknown

The fallback for a type this gem doesn't model — including anything Meta flags as
unsupported. It carries the errors and the whole raw hash, so nothing is lost.

```json
{ "from": "16505551234", "type": "unsupported_future_type",
  "errors": [{ "code": 131051, "title": "Unsupported message type", "message": "m" }] }
```

```ruby
message.type              # => "unsupported_future_type"
message.errors.first.code # => 131051
message.errors.first.title # => "Unsupported message type"
message.raw               # => the complete hash
```

---

## Context

Present when the customer replied to, or forwarded, a message.

```ruby
message.context&.id                    # => "wamid.HBg..."  — the message replied to
message.context&.from                  # => the sender of that message
message.context&.forwarded             # => true | false
message.context&.frequently_forwarded  # => true | false
```

`context` is `nil` — not an all-nil object — when the key is absent, so `&.` is the
right idiom.

## Referral

Present when the conversation started from a click-to-WhatsApp ad or post.

| Accessor | Meaning |
| --- | --- |
| `source_url` | The ad or post URL |
| `source_type` | `"ad"` or `"post"` |
| `source_id` | The ad or post ID |
| `headline` | Ad headline |
| `body` | Ad body |
| `media_type` | `"image"` or `"video"` |
| `image_url` `video_url` `thumbnail_url` | Creative assets |

```ruby
message.referral&.source_type  # => "ad"
message.referral&.headline     # => "Big sale"
```

---

## Statuses

Delivery receipts for messages **you** sent. They arrive on the same `messages` field.

```json
{ "id": "wamid.HBg", "status": "delivered", "timestamp": "1750263773",
  "recipient_id": "16505551234",
  "conversation": { "id": "6ceb9d9", "origin": { "type": "service" } },
  "pricing": { "billable": true, "pricing_model": "CBP", "category": "service" },
  "errors": [{ "code": 131026, "title": "Message undeliverable", "message": "m" }] }
```

```ruby
status = value.statuses.first

status.id            # => "wamid.HBg"      — matches what send! returned
status.status        # => "delivered"      — sent | delivered | read | failed
status.timestamp     # => "1750263773"
status.recipient_id  # => "16505551234"
```

| Accessor | Type |
| --- | --- |
| `conversation` | `Status::Conversation` — `id`, `origin_type`, `expiration_timestamp` |
| `pricing` | `Status::Pricing` — `billable`, `pricing_model`, `category` |
| `errors` | `Array<Webhook::Error>` — populated on `"failed"` |

```ruby
status.conversation.id                    # => "6ceb9d9"
status.conversation.origin_type           # => "service"  | marketing | utility | authentication
status.conversation.expiration_timestamp  # => when the 24-hour window closes

status.pricing.billable       # => true
status.pricing.pricing_model  # => "CBP"
status.pricing.category       # => "service"
```

Correlating a status back to your own record:

```ruby
response = Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hi")
OutboundMessage.create!(wamid: response.messages.first.id)

# ... later, in the webhook handler
value.statuses.each do |status|
  OutboundMessage.find_by(wamid: status.id)&.update!(state: status.status)
end
```

## Errors

`Whatsapp::Webhook::Error` is a **value object**, not an exception — it models Meta's
error payloads on `Status#errors` and `Message::Unknown#errors`.

```ruby
error = status.errors.first
error.code     # => 131026
error.title    # => "Message undeliverable"
error.message  # => "m"
error.details  # => dug from error_data.details
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview>
