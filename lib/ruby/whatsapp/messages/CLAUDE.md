# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory contains every message type supported by the WhatsApp Cloud API. Each file maps directly to one API message type. The entry point `messages.rb` (one level up) acts as a factory that resolves the correct class by kind and calls `send!`; it also defines a `send_<kind>!` convenience class method per entry in its `KINDS` registry (e.g. `Whatsapp::Messages.send_text!(to:, body:)`), generated automatically so a new kind gets one for free the moment it's registered.

## Conventions

### Every message class must follow this structure

1. **Inherit from `Base`** — gets `ActiveModel::Validations` and the `Messaging` constants (`messaging_product`, `recipient_type`).
2. **Define a `Defaults::TYPE` constant** — the string value sent as `type` in the API payload (e.g. `"text"`, `"video"`).
3. **Declare attributes with `attr_accessor`** — annotate each with `# @!attribute` YARD tags.
4. **Add `ActiveModel` validations** — use `validates` for simple rules; use a private `validate_*` method for complex cross-field rules (e.g. `validate_id_or_link` in `Video`).
5. **Call `super(**kwargs)` then `validate!` in `initialize`** — `super` passes `:to` up to `Base`; the second `validate!` runs the subclass validations after attributes are set.
6. **Implement `serialize`** — returns a `Hash` with the full API payload. Common fields (`messaging_product`, `recipient_type`, `to`, `type`) come first; the type-specific payload is a nested key matching `Defaults::TYPE`.
7. **Extract private payload helpers** — when the type-specific hash has optional fields, move it to a private `*_payload` method and call `.compact` to drop `nil` values.
8. **Add a doc comment and source URL** — the class comment must describe the message type and include a `# Source:` line pointing to the official Meta developer docs.

### Sub-objects (nested value objects)

Classes like `Template::Language`/`Component`/`Parameter`, `Contacts::Name`/`Phone`/`Email`/`Address`/`Org`/`Url`, and `Interactive::Header`/`Body`/`Footer` plus its action-shape classes are plain Ruby objects (no `Base` inheritance — they don't have a `to`, `messaging_product`, etc.). They follow the same `initialize` / `serialize` pattern and optionally expose a class-level `.serialize(**kwargs)` shorthand that builds an instance and calls `#serialize` immediately. Use this pattern for any nested structure the API expects as a sub-hash.

### Response deserialization

Every message class that returns a structured API response has a corresponding `Response` sub-object tree:

```
Response                         # top-level: messaging_product, contacts, messages
  Response::Contacts             # input, wa_id
  Response::Messages             # id
```

Each class exposes a class-level `.deserialize(data)` that maps raw JSON hash keys to typed attributes. When adding a new message type that returns additional response fields, extend this tree rather than adding ad-hoc parsing elsewhere.

### Stub classes

There are currently no stub classes — every registered message type is implemented. When adding a new type, follow the full structure above (do not take shortcuts), and write the failing spec first (TDD).

## Message Kinds Reference

One entry per kind registered in `KINDS` (`lib/ruby/whatsapp/messages.rb`). Every example below has been run against the real classes (`bundle exec ruby -Ilib`), and most have been sent through the live Meta Cloud API during development — the serialized output shown is exact, not illustrative.

### Text (`text.rb`)

The default way to carry a conversational reply or notice — most other kinds exist because they need to express something plain text can't (media, buttons, structured data).

- `body:` required (max 4096 chars). `preview_url:` optional, defaults to `true`.

```ruby
Whatsapp::Messages::Text.new(to: "+15551234567", body: "Hello from ruby-whatsapp!").serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "text",
#   text: { body: "Hello from ruby-whatsapp!", preview_url: true }
# }
```

### Image (`image.rb`)

Shares a photo or graphic — e.g. a product photo or receipt.

- Either `id:` (an uploaded [`Media`](../media.rb) asset) or `link:` is required. `caption:` optional (max 1024 chars).

```ruby
Whatsapp::Messages::Image.new(to: "+15551234567", link: "https://example.com/photo.jpg", caption: "Our new product").serialize
# => { ..., type: "image", image: { link: "https://example.com/photo.jpg", caption: "Our new product" } }
```

### Video (`video.rb`)

Shares a video, e.g. an instructional or demo clip.

- Either `id:` or `link:` required. `caption:` optional (max 1024 chars).

```ruby
Whatsapp::Messages::Video.new(to: "+15551234567", id: "1234567890", caption: "Demo video").serialize
# => { ..., type: "video", video: { id: "1234567890", caption: "Demo video" } }
```

### Audio (`audio.rb`)

Sends a voice note or audio clip. Explicitly no caption field — Meta's API doesn't support one for audio.

- Either `id:` or `link:` required.

```ruby
Whatsapp::Messages::Audio.new(to: "+15551234567", link: "https://example.com/clip.mp3").serialize
# => { ..., type: "audio", audio: { link: "https://example.com/clip.mp3" } }
```

### Document (`document.rb`)

Shares a file — an invoice, contract, PDF, etc. — with an optional caption and display filename.

- Either `id:` or `link:` required. `caption:` (max 1024 chars) and `filename:` optional.

```ruby
Whatsapp::Messages::Document.new(to: "+15551234567", link: "https://example.com/invoice.pdf", filename: "invoice.pdf").serialize
# => { ..., type: "document", document: { link: "https://example.com/invoice.pdf", filename: "invoice.pdf" } }
```

### Sticker (`sticker.rb`)

Sends a WhatsApp sticker asset.

- Either `id:` or `link:` required — prefer `id` (via `Media#upload`) over `link` for performance.

```ruby
Whatsapp::Messages::Sticker.new(to: "+15551234567", id: "STICKER_MEDIA_ID").serialize
# => { ..., type: "sticker", sticker: { id: "STICKER_MEDIA_ID" } }
```

### Reaction (`reaction.rb`)

Acknowledges a previous message with an emoji, mirroring the native tap-and-hold reaction UX, without cluttering the thread with a new text message.

- `message_id:` and `emoji:` required. An empty string `emoji:` removes a reaction you sent previously.

```ruby
Whatsapp::Messages::Reaction.new(to: "+15551234567", message_id: "wamid.HBg...", emoji: "\u{1F44D}").serialize
# => { ..., type: "reaction", reaction: { message_id: "wamid.HBg...", emoji: "👍" } }
```

### Location (`location.rb`)

Shares a fixed latitude/longitude pin — e.g. a shop or pickup point.

- `latitude:`/`longitude:` required (numeric). `name:`/`address:` optional.

```ruby
Whatsapp::Messages::Location.new(to: "+15551234567", latitude: 37.4847, longitude: -122.1477, name: "Meta HQ").serialize
# => { ..., type: "location", location: { latitude: 37.4847, longitude: -122.1477, name: "Meta HQ" } }
```

### Contacts (`contacts.rb` + `contacts/*.rb`)

Shares a structured, vCard-like contact card the recipient can tap to save, instead of typing a phone number or email in plain text. `Contact` composes `Name` (required), and optional `Phone`, `Email`, `Address`, `Org`, `Url` sub-objects.

- `contacts:` required, must contain **exactly one** contact — the Cloud API currently rejects zero or more than one.

```ruby
Whatsapp::Messages::Contacts.new(
  to: "+15551234567",
  contacts: [
    {
      name: { formatted_name: "Jane Doe", first_name: "Jane", last_name: "Doe" },
      phones: [{ phone: "+15550001111", type: "WORK" }],
      emails: [{ email: "jane@example.com", type: "WORK" }],
      org: { company: "Acme Inc." },
      birthday: "1990-05-12",
    },
  ]
).serialize
# => { ..., type: "contacts", contacts: [{ name: { formatted_name: "Jane Doe", first_name: "Jane", last_name: "Doe" },
#      phones: [{ phone: "+15550001111", type: "WORK" }], emails: [{ email: "jane@example.com", type: "WORK" }],
#      org: { company: "Acme Inc." }, birthday: "1990-05-12" }] }
```

> **Known quirk:** `Contacts::Name` only validates presence of `formatted_name`. Live testing against the Cloud API got `(#131009) ContactName should have atleast one optional value be set along with formatted Name` — Meta actually requires at least one more name field (e.g. `first_name`) alongside `formatted_name`, which this class doesn't currently enforce. Not yet fixed.

### Address (`address.rb`)

Collects or confirms a structured delivery address via a native form, instead of parsing a free-text reply. **India (`IN`) and Singapore (`SG`) only** — this is a Meta feature-availability restriction on the WhatsApp Business Account, not just a payload field. Serializes as an `interactive` message on the wire (`interactive.type: "address_message"`) despite being a distinct Ruby class.

- `body:`/`country:` required (`country` must be `"IN"` or `"SG"`). `footer:`, `values:`, `saved_addresses:` optional.

```ruby
Whatsapp::Messages::Address.new(
  to: "+15551234567",
  body: "Please share your delivery address",
  country: "IN",
  footer: "Thanks for shopping with us",
  values: { name: "Jane Doe", city: "Bangalore" }
).serialize
# => { ..., type: "interactive", interactive: { type: "address_message", body: { text: "Please share your delivery address" },
#      action: { name: "address_message", parameters: { country: "IN", values: { name: "Jane Doe", city: "Bangalore" } } },
#      footer: { text: "Thanks for shopping with us" } } }
```

Live testing against a WABA not provisioned for this feature returned `(#131009) Unsupported Interactive Message type` — that's expected for any business outside IN/SG, not a bug in this class.

### Location Request (`location_request.rb`)

Asks the user to *share their current location back to the business* — the inverse of `Location` — e.g. to coordinate delivery or pickup. Also serializes as an `interactive` message (`interactive.type: "location_request_message"`).

- `body:` required (max 1024 chars) — the prompt text shown to the user.

```ruby
Whatsapp::Messages::LocationRequest.new(to: "+15551234567", body: "Can you share your delivery location?").serialize
# => { ..., type: "interactive",
#      interactive: { type: "location_request_message", body: "Can you share your delivery location?",
#                      action: { name: "send_location" } } }
```

> **Known quirk:** `body:` is serialized as a bare string, but live testing got a Meta JSON-schema rejection — `interactive.body` must be `[object, null]`, not a string. `Address` and `Interactive` both wrap body text as `{ text: ... }`; `LocationRequest` should too, but currently doesn't. Confirmed broken against the live API, not yet fixed.

### Template (`template.rb` + `template/*.rb`)

The **only** way to message a user outside the 24-hour customer-service window — marketing, utility, and authentication templates must be pre-approved by Meta before they can be sent. Composes `Language` (validated against `Whatsapp::Utils::LanguageCodes`), and optional `Component`s (`header`/`body`/`button`), each with typed `Parameter`s (`text`, `currency`, `date_time`, `image`, `document`, `video`, `location`, `payload`).

- `name:`/`language:` required. `components:` optional (default `[]`).

```ruby
Whatsapp::Messages::Template.new(
  to: "+15551234567",
  name: "order_confirmation",
  language: { code: "en_US" },
  components: [
    { type: "body", parameters: [{ type: "text", text: "Jane" }, { type: "text", text: "#1234" }] },
  ]
).serialize
# => { ..., type: "template", template: { name: "order_confirmation", language: { code: "en_US" },
#      components: [{ type: "body", parameters: [{ type: "text", text: "Jane" }, { type: "text", text: "#1234" }] }] } }
```

### Interactive (`interactive.rb` + `interactive/*.rb`)

Gives the user tappable UI — buttons, a list, a carousel — instead of asking them to type a free-text reply (e.g. tapping "Confirm" vs. typing "yes"). Unlike every other kind, `Interactive` is a **single class** that dispatches on `type:` through the `ACTION_TYPES` registry, never `const_get` on caller input:

```ruby
ACTION_TYPES = {
  reply_buttons:    { klass: ReplyButtons,    api_type: "button" },
  list_buttons:     { klass: ListButtons,     api_type: "list" },
  url_button:       { klass: UrlButton,       api_type: "cta_url" },
  media_carousel:   { klass: MediaCarousel,   api_type: "carousel" },
  product_carousel: { klass: ProductCarousel, api_type: "product_list" },
}
```

Each action class inherits `Interactive::Base` and exposes a class-level `.serialize(**action_kwargs)`. `header:`, `body:`, and `footer:` are always serialized through their own single-purpose classes (`Header`, `Body`, `Footer`) regardless of action kind.

- `type:`, `body:`, `action:` required (`type` must be one of the `ACTION_TYPES` keys; `action`'s shape depends on which). `header:`/`footer:` optional.

**`:reply_buttons`** (live-confirmed) — up to 3 quick-reply buttons:

```ruby
Whatsapp::Messages::Interactive.new(
  to: "+15551234567", type: :reply_buttons, body: "Would you like to confirm your order?",
  action: { buttons: [{ id: "confirm", title: "Confirm" }, { id: "cancel", title: "Cancel" }] }
).serialize
# => { ..., interactive: { type: "button", body: { text: "Would you like to confirm your order?" },
#      action: { buttons: [{ type: "reply", reply: { id: "confirm", title: "Confirm" } },
#                          { type: "reply", reply: { id: "cancel", title: "Cancel" } }] } } }
```

**`:list_buttons`** (live-confirmed) — a button expanding into up to 10 sections of up to 10 rows each:

```ruby
Whatsapp::Messages::Interactive.new(
  to: "+15551234567", type: :list_buttons, body: "Choose a drink",
  action: { button: "Menu", sections: [
    { title: "Coffee", rows: [{ id: "espresso", title: "Espresso", description: "Strong & short" }] },
  ] }
).serialize
# => { ..., interactive: { type: "list", body: { text: "Choose a drink" },
#      action: { button: "Menu", sections: [{ title: "Coffee",
#                rows: [{ id: "espresso", title: "Espresso", description: "Strong & short" }] }] } } }
```

**`:url_button`** — surfaces a link as a button (wire type `cta_url`):

```ruby
Whatsapp::Messages::Interactive.new(
  to: "+15551234567", type: :url_button, body: "Check out our new arrivals",
  action: { name: "cta_url", display_text: "Shop now", url: "https://example.com/new" }
).serialize
# => { ..., interactive: { type: "cta_url", body: { text: "Check out our new arrivals" },
#      action: { name: "cta_url", parameters: { display_text: "Shop now", url: "https://example.com/new" } } } }
```

**`:media_carousel`** — 2 to 10 swipeable cards, each with its own header/body/CTA/quick-replies. **Note:** the wire value `"carousel"` is flagged in the source as worth double-checking against Meta's docs for your API version before relying on it in production.

**`:product_carousel`** — 2 to 10 cards referencing products in a Meta catalog (`catalog_id:`/`product_retailer_id:` per card). Same caveat applies to the wire value `"product_list"`.

## Adding a new message type (checklist)

- [ ] Write a failing spec under `spec/ruby/whatsapp/messages/<type>_spec.rb`
- [ ] Create `lib/ruby/whatsapp/messages/<type>.rb` inheriting `Base`
- [ ] Define `Defaults::TYPE`, attributes, validations, `initialize`, `serialize`
- [ ] Add doc comment + `# Source:` URL to the Meta developer docs
- [ ] Add response deserialization class(es) under `response/` if the API returns new fields
- [ ] Register the type in the `KINDS` registry hash in `messages.rb` (one level up) — this also gets it a `send_<kind>!` convenience method for free, no extra work needed
- [ ] Add a "Message Kinds Reference" entry to this file: why it exists, required/optional fields, a verified example
- [ ] Run `bundle exec rspec` and `bundle exec rubocop` before committing
