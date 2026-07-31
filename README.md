# ruby-whatsapp

[![Gem Version](https://img.shields.io/gem/v/ruby-whatsapp.svg)](https://rubygems.org/gems/ruby-whatsapp)
[![Build Status](https://github.com/saleszera/ruby-whatsapp/actions/workflows/main.yml/badge.svg)](https://github.com/saleszera/ruby-whatsapp/actions/workflows/main.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A small, dependency-light Ruby client for the [Meta WhatsApp Cloud API](https://developers.facebook.com/documentation/business-messaging/whatsapp). Every message type the Cloud API supports — text, media, location, contacts, templates, and the full family of interactive messages (reply buttons, lists, CTA URLs, carousels) — is modeled as its own `ActiveModel`-validated Ruby class, so a malformed payload raises locally instead of round-tripping to Meta's servers first. The gem also handles media upload/download and parses API responses into typed objects.

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [Features](#features)
- [Sending Messages](#sending-messages)
  - [Text](#text)
  - [Image](#image)
  - [Video](#video)
  - [Audio](#audio)
  - [Document](#document)
  - [Sticker](#sticker)
  - [Reaction](#reaction)
  - [Location](#location)
  - [Contacts](#contacts)
  - [Address](#address)
  - [Location Request](#location-request)
  - [Template](#template)
  - [Interactive](#interactive)
- [Handling Responses](#handling-responses)
- [Media](#media)
- [Webhooks](#webhooks)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add to your Gemfile:

```ruby
gem "ruby-whatsapp"
```

Then run `bundle install`. Or install directly:

```bash
gem install ruby-whatsapp
```

## Configuration

```ruby
Whatsapp.configure do |config|
  config.api_key  = ENV.fetch("WHATSAPP_TOKEN")   # a Meta system-user / app access token
  config.phone_id = ENV.fetch("WHATSAPP_PHONE_ID") # the sending phone number ID
  # optional overrides:
  # config.version      = "v24.0"
  # config.host         = "https://graph.facebook.com"
  # config.waba_id      = ENV.fetch("WHATSAPP_WABA_ID")
  # config.verify_token = ENV.fetch("WHATSAPP_VERIFY_TOKEN") # for webhooks, see below
  # config.app_secret   = ENV.fetch("WHATSAPP_APP_SECRET")   # for webhooks, see below
end
```

`api_key`, `app_secret`, and `verify_token` are redacted from `Configuration#inspect`, so they will not leak into logs.

## Quick Start

```ruby
require "ruby/whatsapp"

Whatsapp.configure do |config|
  config.api_key  = ENV.fetch("WHATSAPP_TOKEN")
  config.phone_id = ENV.fetch("WHATSAPP_PHONE_ID")
end

response = Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hello from ruby-whatsapp!")

response.messages.first.id # => "wamid.HBgLMTU1NTU1NTU1NTUV..."
```

## Features

- **Typed, validated message classes** for every Cloud API message kind — invalid payloads raise before any HTTP request is made.
- **Persistent HTTP connections** via `HTTP.persistent`, reused across requests.
- **Pluggable instrumentation** — pass a `Logger` to `Whatsapp::Client.new` to log every request/response.
- **Hardened media downloads** — `Media#download` refuses to attach the bearer token to non-HTTPS URLs or hosts outside an allowlist, so a token can never leak to an attacker-influenced URL.
- **Structured response parsing** — `Whatsapp::Messages::Response` exposes typed `#contacts` and `#messages` instead of raw JSON.

## Sending Messages

Every registered message kind gets its own `Whatsapp::Messages.send_<kind>!` class method — pass the recipient and the kind-specific fields as keyword arguments:

```ruby
Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hello!")
```

Each `send_<kind>!` method accepts an optional `client:` keyword (defaults to a new `Whatsapp::Client` built from `Whatsapp.configuration`) and returns a `Whatsapp::Messages::Response` (see [Handling Responses](#handling-responses)). It raises `ActiveModel::ValidationError` if any field fails validation, and `Whatsapp::RequestError` on a non-2xx API response.

If the kind is only known at runtime, drop down to the underlying factory these methods are built on:

```ruby
Whatsapp::Messages.new(
  kind: :text, # or a variable
  payload: { to: "+15551234567", body: "Hello!" },
  client: Whatsapp::Client.new # optional — defaults to a new Client built from Whatsapp.configuration
).send!
```

This form raises `Whatsapp::Messages::PayloadError` for an unknown `kind` (in addition to the same validation/request errors above).

| Method | Sends |
| --- | --- |
| [`send_text!`](#text) | Plain text with an optional link preview |
| [`send_image!`](#image) | An image with an optional caption |
| [`send_video!`](#video) | A video with an optional caption |
| [`send_audio!`](#audio) | An audio clip |
| [`send_document!`](#document) | A file with an optional caption and filename |
| [`send_sticker!`](#sticker) | A sticker |
| [`send_reaction!`](#reaction) | An emoji reaction to a previous message |
| [`send_location!`](#location) | A latitude/longitude pin |
| [`send_contacts!`](#contacts) | A rich contact card |
| [`send_address!`](#address) | A delivery-address request/confirmation form (India & Singapore only) |
| [`send_location_request!`](#location-request) | A prompt asking the user to share their location |
| [`send_template!`](#template) | A pre-approved marketing/utility/authentication template |
| [`send_interactive!`](#interactive) | Reply buttons, lists, CTA URLs, or carousels |

### Text

```ruby
Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hello!", preview_url: false)
```

`body` is required (max 4096 characters). `preview_url` defaults to `true`.

### Image

```ruby
Whatsapp::Messages.send_image!(
  to: "+15551234567",
  link: "https://example.com/photo.jpg",
  caption: "Our new product"
)
```

Either `id` (an uploaded [media](#media) ID) or `link` is required. `caption` is optional (max 1024 characters).

### Video

```ruby
Whatsapp::Messages.send_video!(to: "+15551234567", id: "1234567890", caption: "Demo video")
```

Either `id` or `link` is required. `caption` is optional (max 1024 characters).

### Audio

```ruby
Whatsapp::Messages.send_audio!(to: "+15551234567", link: "https://example.com/clip.mp3")
```

Either `id` or `link` is required. Audio messages do not support captions.

### Document

```ruby
Whatsapp::Messages.send_document!(
  to: "+15551234567",
  link: "https://example.com/invoice.pdf",
  filename: "invoice.pdf"
)
```

Either `id` or `link` is required. `caption` (max 1024 characters) and `filename` are optional.

### Sticker

```ruby
Whatsapp::Messages.send_sticker!(to: "+15551234567", id: "STICKER_MEDIA_ID")
```

Either `id` or `link` is required — prefer `id` (from [`Media#upload`](#media)) over `link` for performance.

### Reaction

```ruby
Whatsapp::Messages.send_reaction!(to: "+15551234567", message_id: "wamid.HBg...", emoji: "👍")
```

`message_id` and `emoji` are required. Pass `emoji: ""` to remove a reaction you sent previously.

### Location

```ruby
Whatsapp::Messages.send_location!(to: "+15551234567", latitude: 37.4847, longitude: -122.1477, name: "Meta HQ")
```

`latitude` and `longitude` are required. `name` and `address` are optional.

### Contacts

```ruby
Whatsapp::Messages.send_contacts!(
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
)
```

`contacts` must contain exactly one contact — the Cloud API currently allows only one per message. Each contact requires a `name.formatted_name`; `phones`, `emails`, `addresses`, `org`, `urls`, and `birthday` are all optional.

### Address

```ruby
Whatsapp::Messages.send_address!(
  to: "+15551234567",
  body: "Please share your delivery address",
  country: "IN",
  footer: "Thanks for shopping with us",
  values: { name: "Jane Doe", city: "Bangalore" }
)
```

Only available for businesses based in India (`country: "IN"`) or Singapore (`country: "SG"`). `body` and `country` are required; `footer`, `values`, and `saved_addresses` are optional.

### Location Request

```ruby
Whatsapp::Messages.send_location_request!(to: "+15551234567", body: "Can you share your delivery location?")
```

Prompts the user to share their current location. `body` is required.

### Template

```ruby
Whatsapp::Messages.send_template!(
  to: "+15551234567",
  name: "order_confirmation",
  language: { code: "en_US" },
  components: [
    { type: "body", parameters: [{ type: "text", text: "Jane" }, { type: "text", text: "#1234" }] },
  ]
)
```

`name` and `language` are required — `language.code` is validated against `Whatsapp::Utils::LanguageCodes`. `components` is optional and follows the Cloud API's `header`/`body`/`button` component shape, each with typed `parameters` (`text`, `currency`, `date_time`, `image`, `document`, `video`, `location`, or `payload`).

### Interactive

Interactive messages share one class, `Whatsapp::Messages::Interactive`; the `type:` you pass selects which action shape `action:` must match. All variants accept an optional `header:` (`text`, `image`, `video`, or `document`) and `footer:`.

**Reply buttons** — up to 3 quick-reply buttons:

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :reply_buttons,
  body: "Would you like to confirm your order?",
  action: { buttons: [{ id: "confirm", title: "Confirm" }, { id: "cancel", title: "Cancel" }] }
)
```

**List** — a button that expands into up to 10 sections of up to 10 rows each:

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :list_buttons,
  body: "Choose a drink",
  action: {
    button: "Menu",
    sections: [
      { title: "Coffee", rows: [{ id: "espresso", title: "Espresso", description: "Strong & short" }] },
    ],
  }
)
```

**CTA URL button** — surfaces a link as a button instead of raw text:

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :url_button,
  body: "Check out our new arrivals",
  action: { name: "cta_url", display_text: "Shop now", url: "https://example.com/new" }
)
```

**Media carousel** — 2 to 10 swipeable cards, each with its own header/body/CTA/quick-replies:

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :media_carousel,
  body: "Today's picks",
  action: {
    cards: [
      {
        header: { type: "image", link: "https://example.com/1.jpg" },
        body: "Item one",
        action: { name: "cta_url", display_text: "Buy", url: "https://example.com/1" },
        buttons: [{ quick_reply: { id: "q1", title: "Details" } }],
      },
      {
        header: { type: "image", link: "https://example.com/2.jpg" },
        body: "Item two",
        action: { name: "cta_url", display_text: "Buy", url: "https://example.com/2" },
        buttons: [{ quick_reply: { id: "q2", title: "Details" } }],
      },
    ],
  }
)
```

**Product carousel** — 2 to 10 cards referencing products in your Meta catalog:

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :product_carousel,
  body: "Recommended for you",
  action: {
    cards: [
      { catalog_id: "123456789", product_retailer_id: "SKU-1" },
      { catalog_id: "123456789", product_retailer_id: "SKU-2" },
    ],
  }
)
```

> **Note:** the wire values for the carousel types (`"carousel"` and `"product_list"`) are flagged in the source as worth double-checking against Meta's docs for your specific API version before relying on them in production.

## Handling Responses

A successful `send!` returns a `Whatsapp::Messages::Response`, built from a payload shaped like:

```json
{
  "messaging_product": "whatsapp",
  "contacts": [{ "input": "+15551234567", "wa_id": "15551234567" }],
  "messages": [{ "id": "wamid.HBgLMTU1NTU1NTU1NTUV..." }]
}
```

```ruby
response = Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hi")

response.messages.first.id     # => "wamid.HBgLMTU1NTU1NTU1NTUV..."
response.contacts.first.wa_id  # => "15551234567"
```

Sending raises `ActiveModel::ValidationError` if a field fails local validation, `Whatsapp::Messages::PayloadError` if `kind:` is unrecognized (only reachable through the `Messages.new(kind:, payload:).send!` form), and `Whatsapp::RequestError` if the API responds with a non-2xx status.

## Media

```ruby
media = Whatsapp::Media.new

media_id = media.upload(file_path: "photo.jpg", type: "image/jpeg")
info     = media.get_url(media_id: media_id)          # => { "url" => ..., ... }
media.download(url: info["url"], save_to: "photo.jpg") # only HTTPS + allowlisted Meta hosts
media.delete(media_id: media_id)                       # => true
```

`download` refuses to attach the API token to a non-HTTPS URL or a host that is not on
`Configuration#media_host_allowlist`, so a token is never sent to an attacker-influenced URL.

## Webhooks

Meta pushes inbound messages, delivery statuses, and ~18 other account/template
notification types to a callback URL you register. Inside a Rails app:

```bash
bundle exec rake whatsapp:install:webhook
```

This copies a personalizable controller to `app/controllers/whatsapp/webhooks_controller.rb`
and prints the routes and configuration you still need to add by hand:

```ruby
# config/routes.rb
get  "/whatsapp/webhooks", to: "whatsapp/webhooks#verify"
post "/whatsapp/webhooks", to: "whatsapp/webhooks#receive"

# config/initializers/whatsapp.rb
Whatsapp.configure do |config|
  config.verify_token = Rails.application.credentials.whatsapp_verify_token
  config.app_secret    = Rails.application.credentials.whatsapp_app_secret
end
```

The generated controller is yours to edit — it deserializes every notification into typed
objects and leaves a `# TODO` where your own handling goes:

```ruby
class Whatsapp::WebhooksController < ApplicationController
  def verify
    challenge = Whatsapp::Webhook::Verification.call(params: params)
    challenge ? render(plain: challenge) : head(:forbidden)
  end

  def receive
    raw_body = request.body.read
    return head(:unauthorized) unless Whatsapp::Webhook::Signature.valid?(
      payload: raw_body, header: request.headers["X-Hub-Signature-256"]
    )

    notification = Whatsapp::Webhook::Notification.deserialize(JSON.parse(raw_body))
    # notification.entry.each { |entry| entry.changes.each { |change| WebhookJob.perform_later(change) } }

    head :ok
  end
end
```

`notification.entry.first.changes.first` gives you a `field` (e.g. `"messages"`) and a typed
`value` — for the `messages` field, `value.messages` and `value.statuses` are arrays of typed
message/status objects (`Whatsapp::Webhook::Message::Text`, `Whatsapp::Webhook::Status`, etc.).
The other ~18 documented fields (`account_alerts`, `message_template_status_update`, and so on)
each deserialize into their own best-effort typed class — see
[`lib/ruby/whatsapp/webhook/CLAUDE.md`](lib/ruby/whatsapp/webhook/CLAUDE.md) for the full field
reference and confidence notes, since Meta's docs don't publish a JSON schema for most of them.

**Multi-tenant apps** (many customers, each with their own Meta App) pass `verify_token:`/
`app_secret:` explicitly instead of relying on the global config default:

```ruby
account = Account.find_by!(slug: params[:account_slug])
Whatsapp::Webhook::Verification.call(params:, verify_token: account.verify_token)
Whatsapp::Webhook::Signature.valid?(payload: raw_body, header:, app_secret: account.app_secret)
```

See Meta's [webhook documentation](https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview) for the full notification catalog, retry behavior, and signature details.

## Development

After checking out the repo, run `bundle install`, then:

```bash
bundle exec rake      # run the specs and RuboCop (the default task)
bundle exec rspec     # specs only
bundle exec rubocop   # lint only
bin/console           # interactive prompt
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/saleszera/ruby-whatsapp.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
