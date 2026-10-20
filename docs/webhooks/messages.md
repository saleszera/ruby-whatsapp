# `messages`

Inbound customer messages and outbound delivery statuses — the field you will spend
almost all your time on, and one of only five fields with a Meta-published JSON
schema (alongside [`user_id_update`](user_id_update.md) and
[`business_username_updates`](business_username_updates.md)).

`Whatsapp::Webhook::Messages` · confidence: **confirmed** — Meta publishes a real JSON
example

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
| `contacts` | `Array<Contact>` — `profile_name`, `username`, `wa_id`, `user_id`, `parent_user_id` |
| `messages` | `Array<Message::*>` |
| `statuses` | `Array<Status>` |

A given notification carries **either** `messages` **or** `statuses`, never both — but
both accessors always return an array, so you can iterate either without a nil check.

> `contacts` here is the value-level sender identity (who wrote to you). It is a
> different thing from [`Message::Contacts`](#contacts) below, which is a contact
> *card* someone shared with you.

### Business-scoped user IDs (BSUID)

Once a WhatsApp user adopts a username, their phone number may stop appearing in
webhooks — `wa_id`/`from`/`recipient_id` are omitted, and the only stable identifier
left is their **business-scoped user ID** (BSUID), a country-code-prefixed string like
`"US.13491208655302741918"` assigned to `user_id`/`from_user_id`/`recipient_user_id`.
Meta sends `user_id`/`from_user_id` with every contact entry and inbound message in its
published examples, whether or not a username has been adopted, and sends
`recipient_user_id` on every delivery status regardless of how you addressed the
message — see [what arrives with which status](#what-arrives-with-which-status) for the
one exception. All of
them deserialize to `nil` rather than raising when absent, so read them as optional. A
`parent_user_id`/`from_parent_user_id`/`recipient_parent_user_id` variant additionally
appears if you have enrolled in [parent BSUIDs](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#parent-business-scoped-user-ids)
(shared across business portfolios). See
[Business-scoped user IDs](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids)
for the full rollout details.

```ruby
contact = value.contacts.first
contact.wa_id           # => "16315551181"  or nil once phone number sharing stops
contact.user_id         # => "US.13491208655302741918" — sent with every contact entry
contact.username        # => "@testusername" or nil — set only once adopted
contact.parent_user_id  # => set only when parent BSUIDs are enabled
```

---

## Message types

Every entry in `messages` is dispatched by its `type` through the frozen
`Message::MESSAGE_TYPES` registry. An unrecognized type falls back to
[`Unknown`](#unknown), never an exception.

All message classes share this envelope from `Message::Base`:

| Accessor | Meaning |
| --- | --- |
| `from` | The customer's WhatsApp ID, or `nil` once they adopt a username (see [BSUID](#business-scoped-user-ids-bsuid)) |
| `from_user_id` | The customer's BSUID — sent on every inbound message; `nil` if absent |
| `from_parent_user_id` | The customer's parent BSUID, present only if enabled |
| `group_id` | Set only if the message was sent in a group chat; `nil` otherwise |
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

When the card arrives from a [`REQUEST_CONTACT_INFO`
button](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#requesting-phone-numbers-from-users)
or a direct in-chat share, two more fields are present:

```ruby
card.origin  # => "contact_request" (button tap) or "other" (shared from the chat)
card.vcard   # => the raw vCard string when origin is "other"; nil for "contact_request"
```

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

When a user's BSUID itself changes (`change_type == "user_changed_user_id"`), the new
identifiers are also present:

```ruby
message.user_id         # => the customer's new BSUID
message.parent_user_id  # => the customer's new parent BSUID, if enabled
```

### Reaction

```json
{ "type": "reaction", "reaction": { "message_id": "wamid.OLD", "emoji": "👍" } }
```

```ruby
message.message_id  # => "wamid.OLD"  — the message being reacted to
message.emoji       # => "👍"          — empty String when a reaction is removed
```

### Revoke

The customer deleted a message they had sent you. A *control* message rather than a
content one: it names a message you already have instead of carrying a body.

```json
{ "from": "16505551234", "id": "wamid.HBg", "timestamp": "1749416383",
  "type": "revoke", "revoke": { "original_message_id": "wamid.ORIGINAL" } }
```

```ruby
message.original_message_id  # => "wamid.ORIGINAL" — the message to delete on your side
message.id                   # => "wamid.HBg" — the revoke notification's own wamid
```

Also arrives through [`smb_message_echoes`](smb_message_echoes.md) when the *business*
revokes a message from the WhatsApp Business app.

### Edit

The customer edited a message they had sent you. Names the message being replaced and
carries the replacement content.

```json
{ "from": "16505551234", "id": "wamid.HBg", "timestamp": "1749416383",
  "type": "edit",
  "edit": { "original_message_id": "wamid.ORIGINAL",
            "message": { "context": { "id": "wamid.CONTEXT" },
                         "type": "image",
                         "image": { "caption": "Now in blue", "id": "media.1" } } } }
```

```ruby
message.original_message_id  # => "wamid.ORIGINAL"
message.message              # => #<Whatsapp::Webhook::Message::Image ...>
message.message.caption      # => "Now in blue"
```

`message` is a full nested `Message::*`, dispatched by its own `type` — so an edited
image behaves exactly like an inbound one. It carries **content only**: the nested
payload has no `from`/`id`/`timestamp` of its own, so those read `nil`. Use the outer
`message.id` and `message.from`.

Also arrives through [`smb_message_echoes`](smb_message_echoes.md) when the *business*
edits a message from the WhatsApp Business app.

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
message.context&.from                  # => the sender of that message, or nil once
                                       #    they adopt a username
message.context&.from_user_id          # => that sender's BSUID
message.context&.from_parent_user_id   # => their parent BSUID, if enrolled
message.context&.forwarded             # => true | false
message.context&.frequently_forwarded  # => true | false
```

`context` is `nil` — not an all-nil object — when the key is absent, so `&.` is the
right idiom.

`from_user_id`/`from_parent_user_id` carry the quoted sender's identity when their phone
number is gone, the same way [`from_user_id` does on the message itself](#business-scoped-user-ids-bsuid).
**Their key names are inferred** by symmetry with `Message::Base` — Meta has not published
a `context` example carrying them, so validate against a real payload before depending on
them.

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
status.recipient_id  # => "16505551234", or nil once sent to a BSUID (see below)
```

| Accessor | Type |
| --- | --- |
| `recipient_user_id` | The recipient's BSUID — sent on every status; see the table below for the `failed` exception |
| `recipient_parent_user_id` | The recipient's parent BSUID, present only if enabled |
| `conversation` | `Status::Conversation` — `id`, `origin_type`, `expiration_timestamp` |
| `pricing` | `Status::Pricing` — `billable`, `pricing_model`, `category` |
| `errors` | `Array<Webhook::Error>` — populated on `"failed"` |

`recipient_id` is present when you sent the message to a phone number (or when the
recipient's phone number is otherwise available). `recipient_user_id` is **not** the
mirror image of that: Meta sends it on every status whatever you addressed, so the two
routinely arrive together.

### What arrives with which status

| | `sent` | `delivered` | `read` | `failed` |
| --- | :---: | :---: | :---: | :---: |
| `recipient_user_id` | always | always | always | only if addressed to a BSUID |
| `contacts[]` | yes | yes | yes | **omitted entirely** |
| `contacts[].profile.username` | omitted | if adopted | if adopted | — |
| `errors` | — | — | — | populated |

Two traps in that table. A `failed` status is the only one that arrives with no
`contacts` array at all, so code that reads `value.contacts.first` while handling
failures must tolerate `nil` — `contacts` is always an Array, but an empty one. And a
`failed` status for a message you addressed to a phone number carries **neither**
identifier beyond `recipient_id`, so a BSUID-keyed lookup has to fall back to the phone
number on that path.

```ruby
# Correlating a failure back to a customer, whichever identifier arrived
status = value.statuses.first
customer =
  Customer.find_by(bsuid: status.recipient_user_id) ||
  Customer.find_by(wa_id: status.recipient_id)
```

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
