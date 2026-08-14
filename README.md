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
  - [Mark Message As Read](#mark-message-as-read)
- [Handling Responses](#handling-responses)
- [Media](#media)
- [Managing Templates](#managing-templates)
- [Managing Subscribed Apps](#managing-subscribed-apps)
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
  # config.waba_id      = ENV.fetch("WHATSAPP_WABA_ID")   # for template management, see below
  # config.verify_token = ENV.fetch("WHATSAPP_VERIFY_TOKEN") # for webhooks, see below
  # config.app_secret   = ENV.fetch("WHATSAPP_APP_SECRET")   # for webhooks, see below
end
```

`api_key`, `app_secret`, and `verify_token` are redacted from `Configuration#inspect` and `Client#inspect`, so they will not leak into logs or error reports.

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
- **Template management** — create, list, edit and delete the message templates on your WhatsApp Business Account from Ruby, with Meta's documented rules checked client-side so a rejection costs a validation error instead of a 24-hour review cycle.
- **Subscribed apps management** — subscribe or unsubscribe this app from a WhatsApp Business Account's webhook notifications, and list who's currently subscribed, straight from Ruby.
- **Inbound webhook parsing** — a typed object tree for all 19 documented Meta notification field types, plus signature verification.

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

### Mark Message As Read

```ruby
Whatsapp::Messages.mark_message_as_read!(message_id: "wamid.HBgLMTU1NTU1NTU1NTUV...")
```

Marks an inbound message — and every earlier message in that conversation — as read, powering the "seen" checkmarks on the user's side. Must be called within 30 days of receipt. Unlike every other kind above, this isn't sent through `Messages.new(kind:, payload:).send!`: there's no recipient or `type` envelope, just `message_id:`, so it has its own dedicated method instead of a `kind:` in the factory.

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

## Managing Templates

[Sending a template](#template) requires one that already exists and has been approved by
Meta. `Whatsapp::MessageTemplates` creates and manages those templates, so they can live in
your codebase and ship from CI instead of being clicked together in WhatsApp Manager.

This is a different API from sending: it addresses your **WhatsApp Business Account**
(`waba_id`, not `phone_id`) and needs the `whatsapp_business_management` permission.

```ruby
Whatsapp.configure do |config|
  config.api_key = ENV["WHATSAPP_API_KEY"]
  config.waba_id = ENV["WHATSAPP_WABA_ID"]
end

templates = Whatsapp::MessageTemplates.new
```

### Creating

```ruby
created = templates.create(
  name: "order_confirmation",           # lowercase alphanumerics and underscores only
  language: "en_US",
  category: "UTILITY",                  # UTILITY | MARKETING | AUTHENTICATION
  components: [
    { type: :header, format: "TEXT", text: "Order {{1}} confirmed", example: ["#1234"] },
    { type: :body,
      text: "Thank you, {{1}}! Your order number is {{2}}.",
      example: ["Pablo", "860198-230332"] },
    { type: :footer, text: "Thanks for shopping with us" },
    { type: :buttons, buttons: [
      { type: :phone_number, text: "Call", phone_number: "15550051310" },
      { type: :url, text: "Track order", url: "https://example.com/orders/{{1}}", example: "1234" },
    ] },
  ]
)

created.id       # => "1259544702043867"
created.status   # => "PENDING" — Meta reviews asynchronously, up to 24 hours
created.pending? # => true
```

Named parameters read better than positional ones for anything non-trivial:

```ruby
templates.create(
  name: "order_confirmation", language: "en_US", category: "UTILITY",
  parameter_format: "NAMED",
  components: [
    { type: :body,
      text: "Thank you, {{first_name}}! Your order number is {{order_number}}.",
      example: { first_name: "Pablo", order_number: "860198-230332" } },
  ]
)
```

Meta's rules are checked before the request, so a mistake raises immediately instead of
costing a review cycle:

```ruby
templates.create(name: "Order Confirmation", ...)
# => ActiveModel::ValidationError: Name must contain only lowercase alphanumeric
#    characters and underscores

templates.create(..., components: [{ type: :body, text: "Hi {{1}} and {{2}}", example: ["Pablo"] }])
# => ActiveModel::ValidationError: Example does not match the body text:
#    2 placeholders but 1 example
```

### Listing, reading, editing, deleting

```ruby
page = templates.list(status: %w[APPROVED], fields: %w[name category status], limit: 25)
page.select(&:approved?).map(&:name)   # Collection is Enumerable
page.remaining                         # headroom against your account's template cap
templates.list(after: page.next_cursor) if page.next_cursor

template = templates.find(template_id: "1259544702043867")
template.status      # => "APPROVED"
template.editable?   # => true (APPROVED, REJECTED and PAUSED templates can be edited)

templates.update(template_id: template.id, category: "MARKETING")  # => true
templates.update(template_id: template.id, components: [...])      # full replacement

templates.delete(name: "order_confirmation")                       # every language variant
templates.delete(hsm_id: "1407680676729941", name: "order_confirmation")
templates.delete(hsm_ids: %w[1387372356726668 1304694804498707])   # up to 100
```

Editing an approved template re-submits it for review but it keeps working meanwhile.
Approved templates allow 10 edits per 30 days and 1 per 24 hours. Deleting an approved
template blocks reuse of its name for 30 days.

### Other template kinds

**Authentication (OTP)** templates invert the usual shape — Meta supplies and localises the
wording, so you pass flags rather than text, and `upsert` creates every language at once:

```ruby
templates.upsert(
  name: "authentication_code", languages: %w[en_US es_ES fr], category: "AUTHENTICATION",
  components: [
    { type: :body, add_security_recommendation: true },
    { type: :footer, code_expiration_minutes: 15 },
    { type: :buttons, buttons: [{ type: :otp, otp_type: "COPY_CODE" }] },
  ]
)
```

**Marketing carousels** take 2–10 cards that must all share the same structure:

```ruby
card = {
  header: { format: "IMAGE", header_handle: "4::aW..." },
  body: { text: "Rare {{1}} in stock!", example: ["Tulips"] },
  buttons: [{ type: :quick_reply, text: "More like this" }],
}

templates.create(
  name: "summer_carousel", language: "en_US", category: "MARKETING",
  components: [
    { type: :body, text: "Summer is here, {{1}}!", example: ["Pablo"] },
    { type: :carousel, cards: [card, card] },
  ]
)
```

**Limited-time offers** add a countdown and a coupon code (marketing only; footers are not
allowed and the body drops to 600 characters):

```ruby
templates.create(
  name: "spring_offer", language: "en_US", category: "MARKETING",
  components: [
    { type: :header, format: "IMAGE", header_handle: "4::aW..." },
    { type: :limited_time_offer, text: "Expiring offer!", has_expiration: true },
    { type: :body, text: "Good news, {{1}}! Use code {{2}} for 25% off.",
      example: ["Pablo", "SPRING25"] },
    { type: :buttons, buttons: [
      { type: :copy_code, example: "SPRING25" },
      { type: :url, text: "Book now!", url: "https://example.com/o?c={{1}}", example: "n3mtql" },
    ] },
  ]
)
```

**Library templates** are pre-written and pre-approved by Meta, so they usually come back
`APPROVED` immediately:

```ruby
templates.create_from_library(
  name: "my_delivery_update", language: "en_US", category: "UTILITY",
  library_template_name: "delivery_update_1",
  library_template_button_inputs: [
    { type: "URL", url: { base_url: "https://example.com/{{1}}",
                          url_suffix_example: "https://example.com/order_update" } },
  ]
)
```

### Notes

- **Media headers** take a `header_handle` you already hold. Producing one needs Meta's
  Resumable Upload API, which this gem does not wrap — note it is a different flow from
  [`Media#upload`](#media), whose media IDs are for *sending*, not template creation.
- **Review outcomes arrive by webhook**, not by polling: see
  `message_template_status_update` and friends under [Webhooks](#webhooks).
- Text containing `#{{1}}` needs single quotes in Ruby, or `#{` starts interpolation.

## Managing Subscribed Apps

Before your app receives any [webhook](#webhooks) notifications for a WhatsApp
Business Account, it needs to be subscribed to it. `Whatsapp::SubscribedApp` wraps the
`subscribed_apps` edge: one class per action, since — unlike templates — these three
actions don't share an identity or validation rules to justify one combined class.

This addresses your **WhatsApp Business Account** (`waba_id`, not `phone_id`) and needs
the `whatsapp_business_management` permission, same as [template management](#managing-templates).

```ruby
Whatsapp.configure do |config|
  config.api_key = ENV["WHATSAPP_API_KEY"]
  config.waba_id = ENV["WHATSAPP_WABA_ID"]
end

Whatsapp::SubscribedApp::Subscribe.call                         # subscribe this app
Whatsapp::SubscribedApp::List.call.map(&:name)                  # => ["My App"]
Whatsapp::SubscribedApp::Unsubscribe.call                       # stop all webhook delivery
```

### Subscribing

```ruby
result = Whatsapp::SubscribedApp::Subscribe.call
result.success       # => true
result.map(&:name)   # => ["My App"] — every app now subscribed, Meta's own echo
```

Tech Providers routing several WABAs' notifications to different callback URLs pass an
override instead of relying on the one callback URL configured on the app itself:

```ruby
Whatsapp::SubscribedApp::Subscribe.call(
  override_callback_uri: "https://example.com/webhooks/acme_corp",
  verify_token: "a-per-account-secret"
)
```

### Listing

```ruby
apps = Whatsapp::SubscribedApp::List.call
apps.map(&:name)          # Collection is Enumerable
apps.first.link           # => "https://www.facebook.com/games/?app_id=..."

Whatsapp::SubscribedApp::List.call(fields: %w[id name])  # restrict the fields returned
```

### Unsubscribing

```ruby
Whatsapp::SubscribedApp::Unsubscribe.call.success   # => true
```

Stops all webhook deliveries for this WABA immediately.

Every action accepts an optional `client:` keyword (defaults to a new
`Whatsapp::Client` built from `Whatsapp.configuration`), and raises
`Whatsapp::SubscribedApp::Error` if no `waba_id` is configured or the API rejects the
request.

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
