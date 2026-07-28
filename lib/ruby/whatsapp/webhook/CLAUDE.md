# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory deserializes and authenticates *inbound* Meta webhook notifications — the opposite direction from `../messages/` (which builds *outbound* API payloads). A host Rails app runs `rake whatsapp:install:webhook` to get a personalizable controller; everything else here turns the raw JSON that controller receives into typed Ruby objects.

## Shape of a notification

```
{ object, entry: [ { id, changes: [ { field, value } ] } ] }
```

`Notification.deserialize(JSON.parse(body))` → `Entry[]` → `Change[]`. Each `Change#field` is one of Meta's ~19 documented webhook field names; `Change#value` is that field's deserialized payload, resolved through `Change::FIELDS` — a frozen `Symbol => Class` hash, the same dispatch-table convention as `Messages::KINDS` and `Interactive::ACTION_TYPES` (**never `const_get` on the field name** — it comes straight from the internet). A field not in `FIELDS` (something Meta adds after this gem is released) falls back to `UnknownField` rather than raising, so the controller never 500s on an unrecognized notification.

## Conventions

Every deserializable class here follows the `Messages::Response` read-side pattern, not the `Messages::Base` write-side one — no `ActiveModel::Validations`, no `serialize`, just a class-level `.deserialize(data)` that string-keys into the raw hash and returns a `new(...)`:

1. Plain Ruby object, `attr_accessor` per field, YARD `@!attribute` tags.
2. `.deserialize(data)` is a class method, tolerant of a `nil`/missing hash (`data ||= {}`) and of missing arrays (`Array(data["key"]).map { ... }`, never `data["key"].map`).
3. Optional nested objects return `nil` when their source key is absent, not an all-nil instance (see `Message::Context.deserialize(nil) #=> nil`).
4. A doc comment with a `# Source:` link to Meta's webhook docs.

### The `messages` field — full typed coverage

`Whatsapp::Webhook::Messages` is the only field with a confirmed, JSON-example-backed schema (Meta's docs show a real payload). It composes:

- `Metadata` (`display_phone_number`, `phone_number_id`)
- `Contact` (`profile_name`, `wa_id`) — the *value-level* `contacts[]` entry, distinct from `Message::Contacts` below
- `Message` — a dispatcher (like `Whatsapp::Messages`, not inherited) resolving `messages[]` entries by `type` through `Message::MESSAGE_TYPES`, to a subclass of `Message::Base` (holds the shared envelope: `from`, `id`, `timestamp`, `type`, `context`, `referral`):
  - `Text`, `Image`/`Video`/`Audio`/`Document`/`Sticker` (share a `Media < Base` superclass: `media_id`, `mime_type`, `sha256`, `caption`), `Location`, `Contacts` (+ nested `Contact`/`Name`/`Phone`/`Email`/`Address`/`Org`/`Url`, mirroring `Messages::Contacts::*` field-for-field but as new read-side classes), `Interactive` (`button_reply`/`list_reply`), `Button`, `Order` (+ `ProductItem`), `System`, `Reaction`, and `Unknown` (fallback — carries `errors[]` and the full raw hash)
- `Status` — delivery status updates (`sent`/`delivered`/`read`/`failed`), with nested `Conversation` and `Pricing`
- `Error` (top-level `Webhook::Error`, shared between `Message::Unknown#errors` and `Status#errors`)

### The other 18 fields — best-effort typed classes

Meta's public docs describe each of these in one line with **no published JSON example** (confirmed by direct fetch — the fuller reference page is client-rendered and not scrapable). Their attribute names below are reconstructed from general WhatsApp Cloud API knowledge, not a verified schema. Each still gets a real class (per an explicit choice to attempt full coverage rather than a generic passthrough), but validate against a real payload (App Dashboard → "send test payload") before depending on these in production — every one of these files says so in its doc comment too.

| Field | Class | Confidence |
| --- | --- | --- |
| `account_alerts` | `AccountAlerts` | Moderate |
| `account_review_update` | `AccountReviewUpdate` | High |
| `account_update` (+ `AccountUpdate::BanInfo`) | `AccountUpdate` | Moderate |
| `automatic_events` | `AutomaticEvents` | Low (`event_data` kept as a raw hash) |
| `business_capability_update` | `BusinessCapabilityUpdate` | Moderate |
| `history` | `History` | Low (`threads` kept as a raw array) |
| `message_template_components_update` | `MessageTemplateComponentsUpdate` | Moderate |
| `message_template_quality_update` | `MessageTemplateQualityUpdate` | Moderate-high |
| `message_template_status_update` | `MessageTemplateStatusUpdate` | High |
| `partner_solutions` | `PartnerSolutions` | Low |
| `payment_configuration_update` | `PaymentConfigurationUpdate` | Moderate |
| `phone_number_name_update` | `PhoneNumberNameUpdate` | Moderate-high |
| `phone_number_quality_update` | `PhoneNumberQualityUpdate` | Moderate |
| `security` | `Security` | Low |
| `smb_app_state_sync` (+ `SmbAppStateSync::StateSync`) | `SmbAppStateSync` | Low-moderate (`contact` kept as a raw hash) |
| `smb_message_echoes` | `SmbMessageEchoes` | Moderate structure (reuses `Message.deserialize` — Meta says these mirror the standard message shape), low on the exact key name |
| `template_category_update` | `TemplateCategoryUpdate` | Moderate-high |
| `user_preferences` | `UserPreferences` | Moderate |

## Authentication

- `Verification.call(params:, verify_token: Whatsapp.configuration.verify_token)` — the one-time GET handshake (`hub.mode`/`hub.verify_token`/`hub.challenge`). Returns the challenge string to echo back, or `nil`.
- `Signature.valid?(payload:, header:, app_secret: Whatsapp.configuration.app_secret)` — HMAC-SHA256 check of the raw body against `X-Hub-Signature-256`.
- Both take the credential as an overridable keyword, defaulting to global `Whatsapp.configuration`. **This override is the multi-tenant path** — an app with many customers, each owning a different Meta App, resolves the right account first and passes its `verify_token`/`app_secret` explicitly instead of relying on the single global default.

## Installer

`Installer.call(root:)` is plain Ruby (no Rails dependency) so it's unit-testable directly — it copies `templates/webhooks_controller.rb.tt` to `<root>/app/controllers/whatsapp/webhooks_controller.rb`, skipping (never overwriting) if that file already exists. `lib/tasks/whatsapp.rake` is a thin Rails-facing wrapper around it (`task webhook: :environment { Installer.call(root: Rails.root) }`), registered automatically by `Whatsapp::Railtie` when the gem is loaded inside a Rails app.

The `.tt` extension on the template (not `.rb`) is deliberate: Zeitwerk only manages `.rb` files, so the template is invisible to it without needing an explicit `loader.ignore`. `Railtie` itself needs the explicit ignore (see `lib/ruby/whatsapp.rb`) since, unlike the template, it is a real `.rb` file defining a real constant — just one that must be required eagerly instead of autoloaded, because Rails discovers `Railtie` subclasses at boot by class definition.

## Adding a new field or message type (checklist)

- [ ] Write a failing spec under `spec/ruby/whatsapp/webhook/...` mirroring the `lib` path
- [ ] Create the class following the `.deserialize(data)` conventions above
- [ ] Register it in `Change::FIELDS` (new top-level field) or `Message::MESSAGE_TYPES` (new message content type)
- [ ] Add a `# Source:` doc comment; note the confidence level if the schema isn't confirmed by a real payload
- [ ] Add a row to the reference table(s) above
- [ ] Run `bundle exec rspec` and `bundle exec rubocop` before committing
