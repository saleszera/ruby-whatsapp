# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory deserializes and authenticates *inbound* Meta webhook notifications — the opposite direction from `../messages/` (which builds *outbound* API payloads). A host Rails app runs `rake whatsapp:install:webhook` to get a personalizable controller; everything else here turns the raw JSON that controller receives into typed Ruby objects.

## Shape of a notification

```
{ object, entry: [ { id, changes: [ { field, value } ] } ] }
```

`Notification.deserialize(JSON.parse(body))` → `Entry[]` → `Change[]`. Each `Change#field` is one of Meta's 21 documented webhook field names; `Change#value` is that field's deserialized payload, resolved through `Change::FIELDS` — a frozen `Symbol => Class` hash, the same dispatch-table convention as `Messages::KINDS` and `Interactive::ACTION_TYPES` (**never `const_get` on the field name** — it comes straight from the internet). A field not in `FIELDS` (something Meta adds after this gem is released) falls back to `UnknownField` rather than raising, so the controller never 500s on an unrecognized notification.

## Conventions

Every deserializable class here follows the `Messages::Response` read-side pattern, not the `Messages::Base` write-side one — no `ActiveModel::Validations`, no `serialize`, just a class-level `.deserialize(data)` that string-keys into the raw hash and returns a `new(...)`:

1. Plain Ruby object, `attr_accessor` per field, YARD `@!attribute` tags.
2. `.deserialize(data)` is a class method, tolerant of a `nil`/missing hash (`data ||= {}`) and of missing arrays (`Array(data["key"]).map { ... }`, never `data["key"].map`).
3. Optional nested objects return `nil` when their source key is absent, not an all-nil instance (see `Message::Context.deserialize(nil) #=> nil`).
4. A doc comment with a `# Source:` link to Meta's webhook docs.
5. An `initialize` keyword takes a `nil` (or `[]`) default exactly when Meta documents that field as *conditional* — present in some payload shapes and not others; every BSUID identifier is, by construction. It stays required only for keys Meta sends on every payload of that shape (`id`, `timestamp`, `type`, `status`, `change_type`), so an `attr_accessor` added without a matching line in `.deserialize` raises immediately instead of reading `nil` forever. `Message::Contacts::Contact` is the reference: its arrays and `name` are required, its `org`/`birthday`/`vcard`/`origin` are not.

### The `messages` field — full typed coverage

`Whatsapp::Webhook::Messages` is one of five fields with a confirmed, JSON-example-backed schema (Meta's docs show a real payload — see also `UserIdUpdate`/`BusinessUsernameUpdates`/`UserPreferences`/`History` below). It composes:

- `Metadata` (`display_phone_number`, `phone_number_id`)
- `Contact` (`profile_name`, `username`, `wa_id`, `user_id`, `parent_user_id`) — the *value-level* `contacts[]` entry, distinct from `Message::Contacts` below. `username`/`user_id`/`parent_user_id` are the [Business-Scoped User ID (BSUID)](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids) fields; `wa_id` can be `nil` once a user adopts a username and their phone number is no longer shareable; `user_id` accompanies every contact entry in Meta's published examples, but it is still typed `[String, nil]` and read defensively. `Status#recipient_user_id` is *not* narrower: Meta sends it on every status regardless of how you addressed the message, and omits it only on a `failed` status for a message sent to a phone number. Two related conditions worth knowing, both exercised in `spec/ruby/whatsapp/webhook/messages_spec.rb`: the value-level `contacts[]` accompanies `sent`/`delivered`/`read` statuses but is omitted entirely for `failed`, and `contacts[].profile.username` is omitted on `sent` while present on `delivered`/`read`.
- `Message` — a dispatcher (like `Whatsapp::Messages`, not inherited) resolving `messages[]` entries by `type` through `Message::MESSAGE_TYPES`, to a subclass of `Message::Base` (holds the shared envelope: `from`, `from_user_id`, `from_parent_user_id`, `group_id`, `id`, `timestamp`, `type`, `context`, `referral` — the BSUID fields are extracted once in `Base.common_attributes` so every subclass gets them for free):
  - `Text`, `Image`/`Video`/`Audio`/`Document`/`Sticker` (share a `Media < Base` superclass: `media_id`, `mime_type`, `sha256`, `caption`), `Location`, `Contacts` (+ nested `Contact`/`Name`/`Phone`/`Email`/`Address`/`Org`/`Url`/`birthday`, plus BSUID-adjacent `vcard`/`origin` for cards shared via a `REQUEST_CONTACT_INFO` button, mirroring `Messages::Contacts::*` field-for-field but as new read-side classes), `Interactive` (`button_reply`/`list_reply`), `Button`, `Order` (+ `ProductItem`), `System` (+ its own `user_id`/`parent_user_id` for the customer's *new* BSUID after a `user_changed_user_id` event), `Reaction`, the two *control* types `Revoke` (`original_message_id`) and `Edit` (`original_message_id` plus a nested `message` recursed back through `Message.deserialize` — content only, so its own `from`/`id`/`timestamp` read `nil`), and `Unknown` (fallback — carries `errors[]` and the full raw hash)
- `Status` — delivery status updates (`sent`/`delivered`/`read`/`failed`), with nested `Conversation` and `Pricing`, plus `recipient_user_id`/`recipient_parent_user_id` alongside `recipient_id` for the same BSUID reason as `Contact`
- `Error` (top-level `Webhook::Error`, shared between `Message::Unknown#errors` and `Status#errors`)

### Four more confirmed fields

All four are part of the same BSUID rollout as the `messages` field above, and all ship with a real Meta JSON example. `UserPreferences` and `History` were previously best-effort and both had the **wrong shape** — Meta nests their entries one level deeper than the gem assumed, so every accessor was permanently `nil`; the published examples are what caught it. Their specs now carry those payloads verbatim as regression guards.

- `UserIdUpdate` (field `user_id_update`) — a user's BSUID changed. Composes the same `Metadata`/`Contact` as `Messages`, plus `updates: Array<UserIdUpdate::Entry>` (`wa_id`, `detail`, `timestamp`, and `user_id`/`parent_user_id` as `UserIdUpdate::IdChange { previous, current }` — one shared value class for both, since they're the identical shape).
- `BusinessUsernameUpdates` (field `business_username_updates`) — a business phone number's username moved between `approved`/`reserved`/`deleted`. Flat class (`display_phone_number`, `username`, `status`); `status` stays a raw string, no enum/predicates, matching this module's convention (see `MessageTemplateStatusUpdate#event`, `AccountUpdate#event`) rather than the write-side `BusinessPhoneNumber::Account::Details` convention.
- `UserPreferences` (field `user_preferences`) — a customer changed a marketing preference. Structurally a twin of `UserIdUpdate`: the same `Metadata`/`Contact`, plus `preferences: Array<UserPreferences::Entry>` read from `value["user_preferences"]`, plus `raw`. `Entry` carries `wa_id`/`user_id`/`parent_user_id` (so a BSUID-only opt-out is identifiable at all), `detail`, `category`, `value`, `timestamp`. Note `Entry#value` sits inside the change's own `value` hash — Meta's naming, kept rather than "improved".
- `History` (field `history`) — chat-history sync, in chunks. `chunks: Array<History::Chunk>` read from `value["history"]`, each chunk owning its *own* `metadata` (`phase`/`chunk_order`/`progress`) and `threads: Array<History::Thread>`; the value-level `metadata` is the ordinary `Webhook::Metadata`, a different object. `Thread` reuses `Webhook::Contact` for its `context` — the existing `username` read already falls back to a flat key, which is where Meta puts it there — and keeps `raw` so the per-message `history_context.status` stays reachable without putting a history-only field on `Message::Base`. `#phase`/`#chunk_order`/`#progress` read through to `chunks.first`, since a delivery normally carries one chunk.

### The other 16 fields — best-effort typed classes

Meta's public docs describe each of these in one line with **no published JSON example** (confirmed by direct fetch — the fuller reference page is client-rendered and not scrapable). The two `smb_*` rows are the partial exception: the BSUID documentation publishes their *entry* shapes, so those are typed, but each field's own array key remains inferred from its name. Their attribute names below are reconstructed from general WhatsApp Cloud API knowledge, not a verified schema. Each still gets a real class (per an explicit choice to attempt full coverage rather than a generic passthrough), but validate against a real payload (App Dashboard → "send test payload") before depending on these in production — every one of these files says so in its doc comment too.

| Field | Class | Confidence |
| --- | --- | --- |
| `account_alerts` | `AccountAlerts` | Moderate |
| `account_review_update` | `AccountReviewUpdate` | High |
| `account_update` (+ `AccountUpdate::BanInfo`) | `AccountUpdate` | Moderate |
| `automatic_events` | `AutomaticEvents` | Low (`event_data` kept as a raw hash) |
| `business_capability_update` | `BusinessCapabilityUpdate` | Moderate |
| `message_template_components_update` | `MessageTemplateComponentsUpdate` | Moderate |
| `message_template_quality_update` | `MessageTemplateQualityUpdate` | Moderate-high |
| `message_template_status_update` | `MessageTemplateStatusUpdate` | High |
| `partner_solutions` | `PartnerSolutions` | Low |
| `payment_configuration_update` | `PaymentConfigurationUpdate` | Moderate |
| `phone_number_name_update` | `PhoneNumberNameUpdate` | Moderate-high |
| `phone_number_quality_update` | `PhoneNumberQualityUpdate` | Moderate |
| `security` | `Security` | Low |
| `smb_app_state_sync` (+ `StateSync`/`Contact`) | `SmbAppStateSync` | High — the BSUID docs publish the contact shape, so it is typed; the `state_sync` array key is still inferred, hence `raw` |
| `smb_message_echoes` (+ `Echo`) | `SmbMessageEchoes` | High — the BSUID docs publish the value-level `contacts` and the per-echo `to`/`to_user_id`/`to_parent_user_id`, which `Echo` carries so `Message::Base` need not; the `message_echoes` array key is still inferred, hence `raw` |
| `template_category_update` | `TemplateCategoryUpdate` | Moderate-high |

## Not implemented

Deliberate omissions, recorded so they read as decisions rather than gaps. (This module
had no such section before — see `../message_templates/CLAUDE.md` and
`../business_phone_number/CLAUDE.md` for the sibling ones.)

- **Group status identifiers.** `Status` does not carry `recipient_type`,
  `recipient_participant_id`, `recipient_participant_user_id`, or
  `recipient_participant_parent_user_id`. They only appear on a status for a message sent
  *to a group*, and this gem wraps no Groups API, so it cannot produce such a message and
  can never receive such a status. Four accessors unreachable through the gem's own
  surface is exactly the speculative typing `KISS` in the root `CLAUDE.md` rules out.
  `Message::Base#group_id` *is* implemented, because an inbound message from a group is
  reachable — it tells you the message came from a group so you can correlate or ignore it.
- **The `calls` field.** Meta documents five call webhook shapes (connected, terminated,
  and status, business- and user-initiated), all of which grew BSUID identifiers in the
  same rollout. Unregistered, because the gem wraps no Calling API; a `calls` notification
  falls to `UnknownField`, which keeps the whole payload on `#raw`.
- **The `group_participants_update` field.** Same reasoning as `calls`. Note this keeps
  `Change::FIELDS` at Meta's 21 documented fields; `calls` and
  `group_participants_update` are additional to that list, not omissions from it.
- **Per-message `history_context`** on a `History::Thread` message, and the equivalent
  echo-only recipient fields, are kept off `Message::Base` on purpose. `Base` is the
  envelope shared by fifteen inbound message types; a field that can only ever appear in
  one context does not belong on it. `History::Thread#raw` and
  `SmbMessageEchoes::Echo` are the two shapes that solve this — a raw escape hatch where
  the field is incidental, a composed wrapper where it is load-bearing.

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
