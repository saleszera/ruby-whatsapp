<h1 align="center">ruby-whatsapp</h1>

<p align="center">
  <strong>A small, dependency-light Ruby client for the Meta WhatsApp Cloud API.</strong>
</p>

<p align="center">
  <a href="https://rubygems.org/gems/ruby-whatsapp"><img alt="Gem Version" src="https://img.shields.io/gem/v/ruby-whatsapp.svg"></a>
  <a href="https://github.com/saleszera/ruby-whatsapp/actions/workflows/main.yml"><img alt="Build Status" src="https://github.com/saleszera/ruby-whatsapp/actions/workflows/main.yml/badge.svg"></a>
  <a href="https://rubygems.org/gems/ruby-whatsapp"><img alt="Downloads" src="https://img.shields.io/gem/dt/ruby-whatsapp.svg"></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg"></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/ruby-%3E%3D%203.2-CC342D.svg"></a>
</p>

---

Every message type the Cloud API supports — text, media, location, contacts,
templates, and the full family of interactive messages — is modeled as its own
`ActiveModel`-validated Ruby class. A malformed payload raises **in your own process,
naming the field that's wrong**, instead of travelling to Meta and coming back as
error `131009` — the catch-all code the Cloud API returns for a too-long caption, an
unsupported message type, a bad message ID, and a dozen other unrelated mistakes.

```ruby
photo = "https://example.com/new-arrivals.jpg"

# Send it 📸
Whatsapp::Messages.send_image!(to: "+15551234567", link: photo, caption: "Just landed")

# Get a field wrong, and you find out here — not from Meta, three seconds later
Whatsapp::Messages.send_image!(to: "+15551234567", link: photo, caption: "x" * 2000)
# => ActiveModel::ValidationError: Caption is too long (maximum is 1024 characters)
```

Beyond sending, the gem covers the whole surface: media upload and download, template
creation and management, inbound webhook parsing, webhook subscription, and phone
number onboarding.

## Table of Contents

- [✨ Why ruby-whatsapp](#-why-ruby-whatsapp)
- [📦 Installation](#-installation)
- [🔧 Configuration](#-configuration)
- [🚀 Quick Start](#-quick-start)
- [📚 Documentation](#-documentation)
- [💬 Sending Messages](#-sending-messages)
- [📋 Managing Templates](#-managing-templates)
- [🔔 Webhooks](#-webhooks)
- [📷 Media](#-media)
- [🔌 Subscribed Apps](#-subscribed-apps)
- [📞 Business Phone Numbers](#-business-phone-numbers)
- [🚨 Errors](#-errors)
- [🧩 Compatibility](#-compatibility)
- [🔨 Development](#-development)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

## ✨ Why ruby-whatsapp

- **Typed, validated message classes** for every Cloud API message kind — invalid
  payloads raise before any HTTP request is made, with the failing attribute named.
- **Template rules checked client-side.** Meta's documented constraints — name format,
  character limits, placeholder/example matching, quick-reply contiguity, carousel
  structure — are enforced locally, so a mistake costs a validation error instead of a
  24-hour review cycle.
- **Hardened media downloads.** `Media#download` refuses to attach your bearer token to
  a non-HTTPS URL or a host outside an allowlist, so a token can never leak to an
  attacker-influenced URL.
- **Secrets stay out of logs.** `api_key`, `app_secret`, and `verify_token` are
  redacted from every `#inspect`, including credentials in transit like a
  registration PIN.
- **Inbound webhooks, fully typed.** An object tree for all 19 documented Meta
  notification fields, plus HMAC signature verification and a Rails controller
  generator.
- **Persistent HTTP connections** via `HTTP.persistent`, reused across requests, with
  pluggable logging.
- **Four runtime dependencies**, no Rails requirement. Rails integration activates
  itself when Rails is present.

## 📦 Installation

```ruby
# Gemfile
gem "ruby-whatsapp"
```

```bash
bundle install
```

Or standalone:

```bash
gem install ruby-whatsapp
```

## 🔧 Configuration

```ruby
Whatsapp.configure do |config|
  config.api_key  = ENV.fetch("WHATSAPP_API_KEY")   # a Meta system-user / app access token
  config.phone_id = ENV.fetch("WHATSAPP_PHONE_ID")  # the sending phone number ID
end
```

| Option | Default | Needed for |
| --- | --- | --- |
| `api_key` | — | Everything |
| `phone_id` | — | Messages, media, phone-number onboarding |
| `waba_id` | — | Template management, subscribed apps |
| `verify_token` | — | The webhook GET handshake |
| `app_secret` | — | Webhook signature verification |
| `host` | `https://graph.facebook.com` | Overriding the API host |
| `version` | `v24.0` | Pinning a Graph API version |
| `media_host_allowlist` | 3 Meta hosts | Media download safety |

**Which ID addresses what** — the most common source of confusion:

```
phone_id  ──►  Messages · Media · BusinessPhoneNumber
               permission: whatsapp_business_messaging

waba_id   ──►  MessageTemplates · SubscribedApp
               permission: whatsapp_business_management
```

`api_key`, `app_secret`, and `verify_token` are redacted from `Configuration#inspect`
and `Client#inspect`, so they will not leak into logs or error reports.

→ **[Full configuration reference](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/configuration.md)**

## 🚀 Quick Start

```ruby
require "ruby/whatsapp"

Whatsapp.configure do |config|
  config.api_key  = ENV.fetch("WHATSAPP_API_KEY")
  config.phone_id = ENV.fetch("WHATSAPP_PHONE_ID")
end

response = Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hello from ruby-whatsapp!")

response.messages.first.id     # => "wamid.HBgLMTU1NTU1NTU1NTUV..."
response.contacts.first.wa_id  # => "15551234567"
```

## 📚 Documentation

| Area | What it covers |
| --- | --- |
| [**Configuration**](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/configuration.md) | Credentials, the client, connection reuse, instrumentation |
| [**Messages**](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/README.md) | Every message kind, one page each, with exact payloads |
| [**Message Templates**](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/message_templates/README.md) | Creating and managing templates: standard, auth, carousel, offers, library |
| [**Webhooks**](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/webhooks/README.md) | Install, verification, signatures, and all 19 notification fields |
| [**Media**](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/media/README.md) | Upload, download, delete, and the token-safety allowlist |
| [**Subscribed Apps**](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/subscribed_app/README.md) | Turning webhook delivery on and off for an account |
| [**Business Phone Numbers**](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/business_phone_number/README.md) | Onboarding: request code → verify → register |
| [**Errors**](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/errors.md) | The exception hierarchy and retry strategy |

Or start at the [documentation index](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/README.md).

## 💬 Sending Messages

Every registered kind gets its own `Whatsapp::Messages.send_<kind>!` class method:

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :reply_buttons,
  body: "Would you like to confirm your order?",
  action: { buttons: [{ id: "confirm", title: "Confirm" },
                      { id: "cancel",  title: "Cancel" }] }
)
```

| Method | Sends |
| --- | --- |
| [`send_text!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/text.md) | Plain text with an optional link preview |
| [`send_image!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/image.md) | An image with an optional caption |
| [`send_video!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/video.md) | A video with an optional caption |
| [`send_audio!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/audio.md) | A voice note or audio clip |
| [`send_document!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/document.md) | A file with an optional caption and filename |
| [`send_sticker!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/sticker.md) | A sticker |
| [`send_reaction!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/reaction.md) | An emoji reaction to a previous message |
| [`send_location!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/location.md) | A latitude/longitude pin |
| [`send_contacts!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/contacts.md) | A rich, vCard-like contact card |
| [`send_address!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/address.md) | A delivery-address form (India & Singapore only) |
| [`send_location_request!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/location_request.md) | A prompt asking the user to share their location |
| [`send_template!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/template.md) | A pre-approved marketing/utility/authentication template |
| [`send_interactive!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/interactive.md) | Reply buttons, lists, CTA URLs, or carousels |
| [`mark_message_as_read!`](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/mark_message_as_read.md) | Closes the read-receipt loop on an inbound message |

Each accepts an optional `client:` and returns a `Whatsapp::Messages::Response` with
typed `#contacts` and `#messages`. Invalid input raises
`ActiveModel::ValidationError` before any request is made.

→ **[Sending messages](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/messages/README.md)**

## 📋 Managing Templates

Sending a template requires one that already exists and has been approved by Meta.
`Whatsapp::MessageTemplates` creates and manages those, so they live in your codebase
and ship from CI instead of being clicked together in WhatsApp Manager.

```ruby
templates = Whatsapp::MessageTemplates.new   # needs waba_id

created = templates.create(
  name: "order_confirmation", language: "en_US", category: "UTILITY",
  components: [
    { type: :body,
      text: "Thank you, {{1}}! Your order number is {{2}}.",
      example: ["Pablo", "860198-230332"] },
    { type: :buttons, buttons: [
      { type: :url, text: "Track order", url: "https://example.com/orders/{{1}}", example: "1234" },
    ] },
  ]
)

created.status   # => "PENDING" — Meta reviews asynchronously, up to 24 hours
```

Meta's rules are checked before the request, so a mistake raises immediately instead of
costing a review cycle:

```ruby
templates.create(name: "Order Confirmation", ...)
# => ActiveModel::ValidationError: Name must contain only lowercase alphanumeric
#    characters and underscores
```

Covers standard, [authentication/OTP](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/message_templates/authentication.md),
[carousel](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/message_templates/carousel.md),
[limited-time offer](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/message_templates/limited_time_offer.md), and
[library](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/message_templates/library.md) templates,
plus list, find, update, and delete.

→ **[Managing templates](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/message_templates/README.md)**

## 🔔 Webhooks

Meta pushes inbound messages, delivery statuses, and ~18 other notification types to a
callback URL you register. Inside a Rails app:

```bash
bundle exec rake whatsapp:install:webhook
```

That copies a personalizable controller to
`app/controllers/whatsapp/webhooks_controller.rb` and prints the routes to add:

```ruby
def receive
  raw_body = request.body.read
  return head(:unauthorized) unless Whatsapp::Webhook::Signature.valid?(
    payload: raw_body, header: request.headers["X-Hub-Signature-256"]
  )

  notification = Whatsapp::Webhook::Notification.deserialize(JSON.parse(raw_body))

  notification.entry.each do |entry|
    entry.changes.each { |change| WebhookJob.perform_later(change) }
  end

  head :ok
end
```

Every notification deserializes into typed objects — no raw hash spelunking:

```ruby
message = change.value.messages.first

message.from    # => "16505551234"
message.id      # => "wamid.HBg..."
message.body    # => "Does it come in another color?"
```

All 19 documented fields get a class. Only `messages` has a Meta-published schema; the
other 18 are best-effort and flagged as such, per field.

→ **[Webhooks](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/webhooks/README.md)**
· [inbound messages & statuses](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/webhooks/messages.md)

## 📷 Media

```ruby
media = Whatsapp::Media.new

media_id = media.upload(file_path: "photo.jpg", type: "image/jpeg")
info     = media.get_url(media_id: media_id)
media.download(url: info["url"], save_to: "photo.jpg")
media.delete(media_id: media_id)                        # => true
```

`download` refuses to attach the API token to a non-HTTPS URL or a host that is not on
`Configuration#media_host_allowlist`, so a token is never sent to an
attacker-influenced URL. Bodies stream to disk rather than buffering in memory.

→ **[Media](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/media/README.md)**

## 🔌 Subscribed Apps

Before your app receives any webhook notifications for a business account, it has to be
subscribed to it:

```ruby
Whatsapp::SubscribedApp::Subscribe.call            # start webhook delivery
Whatsapp::SubscribedApp::List.call.map(&:name)     # => ["My App"]
Whatsapp::SubscribedApp::Unsubscribe.call          # stop it
```

Tech Providers routing several accounts to different callback URLs pass an
`override_callback_uri:`.

→ **[Subscribed apps](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/subscribed_app/README.md)**

## 📞 Business Phone Numbers

A phone number is unusable with Cloud API until it is **registered** — the prerequisite
that makes sending, media, and templates work for it at all.

```
RequestCode  ->  VerifyCode  ->  Register            (onboarding)
(send OTP)       (confirm it)    (activate on Cloud API)

Deregister                                            (the reverse switch)
```

```ruby
Whatsapp::BusinessPhoneNumber::RequestCode.call(code_method: "SMS", language: "en_US")
Whatsapp::BusinessPhoneNumber::VerifyCode.call(code: "123456")
Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834")
Whatsapp::BusinessPhoneNumber::Deregister.call
```

The 6-digit two-step verification PIN and the local-storage region are validated
client-side — which matters here, because a rejected attempt still counts against a
rate limit of 10 requests per number per 72-hour window.

→ **[Business phone numbers](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/business_phone_number/README.md)**

## 🚨 Errors

Everything descends from `Whatsapp::Error`, and each module raises its own subclass so
you can rescue narrowly:

| Class | Raised by |
| --- | --- |
| `Whatsapp::RequestError` | A failed message send |
| `Whatsapp::Messages::PayloadError` | An unknown message kind |
| `Whatsapp::Media::MediaError` | Anything in `Media` |
| `Whatsapp::MessageTemplates::TemplateError` | Anything in `MessageTemplates` |
| `Whatsapp::SubscribedApp::Error` | Anything in `SubscribedApp` |
| `Whatsapp::BusinessPhoneNumber::Error` | Anything in `BusinessPhoneNumber` |

Local validation failures raise `ActiveModel::ValidationError` instead — they happen at
construction time, before any network call, and carry per-attribute detail:

```ruby
rescue ActiveModel::ValidationError => e
  e.model.errors.full_messages
  # => ["Caption is too long (maximum is 1024 characters)"]
```

→ **[Errors](https://github.com/saleszera/ruby-whatsapp/blob/main/docs/errors.md)**

## 🧩 Compatibility

| | |
| --- | --- |
| Ruby | >= 3.2 (CI runs 3.2 and 3.4) |
| Graph API | `v24.0` by default, overridable |
| Rails | Optional. Webhook controller generator activates when Rails is loaded |
| Dependencies | `activemodel`, `http`, `logger`, `zeitwerk` |

## 🔨 Development

After checking out the repo, run `bundle install`, then:

```bash
bundle exec rake      # specs + RuboCop (the default task)
bundle exec rspec     # specs only
bundle exec rubocop   # lint only
bin/console           # interactive prompt
```

## 🤝 Contributing

Bug reports and pull requests are welcome at
<https://github.com/saleszera/ruby-whatsapp>. Please write the failing spec first —
this gem is developed test-first — and make sure `bundle exec rake` is green before
opening a PR.

## 📄 License

Available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

---

![that's all folks](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExaWlsc3ZkcGhiNWlmMXgwZmNhdnAwaWFleDM5YjZlZmRqa2MxcnM0NCZlcD12MV9naWZzX3NlYXJjaCZjdD1n/xUPOqo6E1XvWXwlCyQ/giphy.gif)
