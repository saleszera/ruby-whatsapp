## [0.6.0] - 2026-10-20

Completes the Business-Scoped User ID (BSUID) work that 0.5.0 began. 0.5.0 covered the
inbound webhook half; this covers the send side, the four webhook fields Meta's BSUID
documentation changed but 0.5.0 did not touch, the two new phone-number APIs, and the
button that asks a username adopter for their phone number back.

### Fixed

- **`Whatsapp::Webhook::UserPreferences` and `::History` could never populate.** Both read
  their payload one nesting level too high — `value["wa_id"]` and `value["metadata"]`,
  where Meta nests entries under a repeat of the field's own name
  (`value["user_preferences"][]`, `value["history"][]`), the convention `UserIdUpdate`
  already followed. Every accessor on both classes returned `nil` or `[]` for a real
  payload. The BSUID documentation is the first published example for either field, which
  is what caught it; both specs now carry those payloads verbatim as regression guards.
  **Breaking:** `UserPreferences`' `wa_id`/`detail`/`value`/`timestamp` move to
  `change.value.preferences.first.*`, and `History#threads` moves to
  `chunks.first.threads` — `#phase`/`#chunk_order`/`#progress` keep their names and now
  actually work.
- **Corrected `Status#recipient_user_id`'s documented behavior.** The docs and one spec
  claimed it appears only when you addressed a message to a BSUID. Per Meta's May 4, 2026
  correction it is sent on *every* status however the message was addressed, and omitted
  only on a `failed` status for a message sent to a phone number. The deserializer was
  always right; the claim around it was not. Also newly documented: the status webhook's
  `contacts[]` accompanies `sent`/`delivered`/`read` but is omitted entirely for `failed`,
  and `contacts[].profile.username` is omitted on `sent`.

### Added

- **Send to a BSUID.** `Whatsapp::Messages::Base` gains `recipient` alongside `to`, so a
  BSUID read off a webhook can be replied to without ever knowing the phone number. Supply
  either or both — Meta gives `to` precedence — and at least one is required, which is now
  a validation rather than a missing-keyword `ArgumentError`. Because all 13 message kinds
  already forwarded with `super(**)`, and the `KINDS` factory splats `**payload`, this
  reached every kind and `send_<kind>!` method without touching either. `envelope` compacts
  the recipient pair only, so an omitted identifier is left out rather than sent as null.
  `Messages::Response::Contacts` gains `user_id` and makes `wa_id` optional to match —
  noting that Meta omits `user_id` whenever the message went to a phone number, *including*
  when both identifiers were supplied, so a nil `user_id` does not mean the recipient has
  no BSUID. The BSUID is deliberately not format-checked: its canonical source is this
  gem's own webhook side, which keeps it a raw string, and rejecting on the way out what
  was accepted on the way in would be the worst possible asymmetry.
- **`Whatsapp::BusinessPhoneNumber::Username`** — `Get`, `Claim`, `Delete`, and `Suggest`
  wrap the searchable `@name` a WhatsApp user can find a number by. Four endpoints, three
  wire shapes, two new value classes: `Username::Details` covers both `Get` and `Claim`
  since `{status}` is a subset of `{username, status}`, `Username::Suggestions` owns the
  doubly-wrapped suggestions envelope and is `Enumerable`, and `Delete` reuses the existing
  `BusinessPhoneNumber::Response` for its bare `{success}`. Every one of Meta's published
  username format rules is checked before the request, since the edge is rate limited — bar
  the domain-suffix rule, whose published list ends in "and so on", so a suffix outside the
  documented ten is left to the API. Mixed case is downcased rather than rejected, because
  Meta compares usernames case-insensitively. `Details::Statuses` deliberately omits
  `"deleted"`: that value reaches you only through the `business_username_updates` webhook,
  and a write-side enum must not name a state no endpoint here can return.
- **`Whatsapp::BusinessPhoneNumber::ContactBook::Delete`** — removes a stored user contact
  from the store Meta uses to keep putting a username adopter's phone number in your
  webhooks. Returns its own `ContactBook::Deletion` rather than the shared `Response`,
  because `deleted` is a second independent boolean that changes how `success` reads:
  `success: true, deleted: false` means the request was fine and there was simply nothing
  stored. Rejects a parent BSUID locally — the one BSUID-shape assertion in the gem, and
  safe because it tests for a documented extra segment rather than a country-code grammar
  Meta has never published. Both new namespaces reuse `BusinessPhoneNumber::Transport`
  unchanged; there are still only two transports in that directory, three sub-namespaces
  later.
- **`REQUEST_CONTACT_INFO`**, in both forms: a `MessageTemplates::Button` type for opening
  a conversation with the ask, and a `Messages::Interactive` action kind
  (`type: :request_contact_info`) for making it inside the 24-hour service window. Both
  were previously recorded as deliberately absent for want of a published schema; the BSUID
  documentation publishes one. The template button's `UTILITY`/`MARKETING` restriction lives
  in `ComponentSet` alongside the other cross-component rules, and is checked by drilling
  into the `BUTTONS` component rather than through `CATEGORY_RESTRICTED_TYPES`, which keys
  on component types. The interactive kind is the first with nothing for a caller to
  supply, so `ACTION_TYPES` gained a `parameterless` flag and `action:` is no longer
  required for it.
- **Four more webhook fields brought up to their published schemas.**
  `Whatsapp::Webhook::SmbMessageEchoes` gains a value-level `contacts` array and wraps each
  echo in a new `SmbMessageEchoes::Echo` carrying `to`/`to_user_id`/`to_parent_user_id` —
  a wrapper rather than three more accessors on `Message::Base`, because an inbound message
  can never carry a recipient, and three permanently-nil readers on fifteen classes would
  turn a helpful `NoMethodError` into a silent `nil`. **Breaking:** `echo.body` becomes
  `echo.message.body`. `SmbAppStateSync` gains `messaging_product`/`metadata` and types its
  synced contact as `SmbAppStateSync::Contact` (`full_name`, `first_name`, `phone_number`,
  `user_id`, `parent_user_id`, `username`), with the per-entry `metadata.timestamp`
  flattened onto the entry. **Breaking:** `sync.contact["phone_number"]` becomes
  `sync.contact.phone_number`, and an entry with no contact returns `nil` rather than `{}`.
  All four fields, plus `UserPreferences` and `History`, now expose `raw`.
- **`revoke` and `edit` message types**, registered in `Message::MESSAGE_TYPES` rather than
  falling through to `Message::Unknown`. `Revoke` carries `original_message_id`; `Edit`
  carries that plus a nested `message` recursed back through `Message.deserialize`, so an
  edited image behaves exactly like an inbound one — content only, so the nested payload's
  own `from`/`id`/`timestamp` read `nil`. Both also arrive through `smb_message_echoes`
  when the business edits or revokes from the WhatsApp Business app.
- **`Message::Base#group_id`**, set when an inbound message came from a group chat.
  Extracted once in `common_attributes`, so every message type has it. The matching
  group-status identifiers on `Status` are deliberately *not* added, and are now recorded
  under a new "Not implemented" section in `lib/ruby/whatsapp/webhook/CLAUDE.md` along with
  the `calls` and `group_participants_update` fields: they only appear on a status for a
  message sent to a group, and this gem wraps no Groups API, so it can never receive one.

## [0.5.0] - 2026-08-24

- Add Business-Scoped User ID (BSUID) support to inbound webhooks: Meta is rolling out
  WhatsApp usernames, after which a user's phone number can be omitted from a webhook
  entirely, leaving their BSUID (`user_id`, e.g. `"US.13491208655302741918"`) as the only
  stable identifier. `Whatsapp::Webhook::Contact`, `Message::Base` (and therefore every
  message type: `Text`, the `Media` family, `Location`, `Contacts`, `Interactive`,
  `Button`, `Order`, `System`, `Reaction`, `Unknown`), and `Status` now all carry
  `user_id`/`from_user_id`/`recipient_user_id`, alongside `parent_user_id` variants for
  businesses enrolled in [parent BSUIDs](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#parent-business-scoped-user-ids).
  `Contact` additionally gains `username`. `Message::Contacts::Contact` gains `vcard`/
  `origin` for cards shared via a `REQUEST_CONTACT_INFO` button, and `Message::System`
  gains its own `user_id`/`parent_user_id` for the customer's new BSUID after a
  `user_changed_user_id` event. `Message::Context` carries `from_user_id`/
  `from_parent_user_id` too, so a quoted reply still identifies its sender once the phone
  number is gone. `from_user_id`/`from_parent_user_id` are extracted once in
  `Message::Base.common_attributes`, so every message type gained them without any
  per-type changes.
- Add two new confirmed webhook fields from the same BSUID rollout:
  `Whatsapp::Webhook::UserIdUpdate` (a user's BSUID changed — composes the existing
  `Metadata`/`Contact` plus `Entry`/`IdChange` for the `{previous, current}` change
  records) and `Whatsapp::Webhook::BusinessUsernameUpdates` (a business phone number's
  username moved between `approved`/`reserved`/`deleted`). Both also expose `raw`, the
  untouched `value` hash, so a payload whose shape differs from Meta's published example
  is still recoverable rather than silently deserializing to an empty object.

## [0.4.2] - 2026-08-19

- Add WhatsApp Business Profile management: `Whatsapp::BusinessPhoneNumber::Profile::Get` reads the public card a WhatsApp user sees before they reply — about text, description, address, email, websites, industry vertical, and profile picture URL — and `::Profile::Update` writes them. Unlike `::Account`, this is not an exception to the module's `phone_id` rule: Meta exposes the profile as an edge on the phone number itself (`GET`/`POST /{phone_id}/whatsapp_business_profile`), so both actions reuse the existing `BusinessPhoneNumber::Transport#edge_path` unchanged — no new transport, no new ID to configure. `Update` validates the 21-value `Profile::Verticals` enum and Meta's documented limits (about 139, address 256, description 512, email 128 characters, at most 2 websites) before any request is made, and compacts omitted fields out of the body rather than sending null — which Meta reads as an instruction to blank them — with an empty `websites` array surviving on purpose, since that is how the list is cleared. `email`'s format is deliberately left to Meta, which validates it server-side; a regex here would reject valid exotic addresses. It reuses the existing `BusinessPhoneNumber::Response`, since the endpoint answers a bare `{success}`.
- `Profile::Details` owns Meta's `data` envelope so callers never reach through it. Meta's reference declares the entry as `{"business_profile": {...}}` while live responses are observed to carry the profile fields directly in `data[0]`; `deserialize` reads both rather than betting on one, following the same flatten-the-meaningless-wrapper habit as `SubscribedApp::Response::App` and `MessageTemplates::Response::Paging`. Its `vertical` stays a raw string, never validated or upcased on the way in, so a value Meta adds later still round-trips — compare it against `Verticals::ALL`.

## [0.4.1] - 2026-08-18

- Add WhatsApp Business Account details and updates: `Whatsapp::BusinessPhoneNumber::Account::Get` reads the WABA node — name, timezone, message template namespace, country, and the review, verification, and ownership state — and `::Account::Update` renames the account or moves its timezone. `Get` returns an `Account::Details` carrying `ReviewStatuses`/`VerificationStatuses`/`OwnershipTypes` constants and `#approved?`/`#verified?`/`#self_owned?` predicates; statuses stay raw strings and are never validated on the way in, so a value Meta adds later still round-trips. `Update` validates locally that at least one of `name`/`timezone_id` is present and non-blank before any request is made, and reuses the existing `BusinessPhoneNumber::Response` since the endpoint answers a bare `{success}`. These two live under `BusinessPhoneNumber` but address `waba_id` rather than `phone_id` — the module's one account-scoped corner — so they carry their own transport.

## [0.4.0] - 2026-08-14

- Add subscribed apps management: `Whatsapp::SubscribedApp::List`, `::Subscribe`, and `::Unsubscribe` wrap the `subscribed_apps` edge — the switch that turns a WABA's webhook delivery on or off, as opposed to `Whatsapp::Webhook`, which only deserializes notifications once Meta is already sending them. Responses expose `Collection`, `Subscription`, and `Unsubscription`, each composed from a shared `App` value object.
- Add business phone number registration: `Whatsapp::BusinessPhoneNumber::Register` and `::Deregister` wrap the two endpoints that make a phone number usable — or not — with Cloud API. `Register` validates the 6-digit two-step verification PIN and the `data_localization_region` locally before any request is made.
- Add the phone number verification flow that precedes registration: `Whatsapp::BusinessPhoneNumber::RequestCode` sends a verification code by SMS or voice call, and `::VerifyCode` confirms it, completing the `RequestCode` → `VerifyCode` → `Register` onboarding sequence. `Response` now carries an optional `id`, returned by `VerifyCode`.

## [0.3.1] - 2026-08-13

- Fix `Client#inspect` leaking the raw `api_key` in its default output — and, through it, any object holding a client (`Media#inspect`, `MessageTemplates#inspect`). Now redacted the same way `Configuration#inspect` already was. If a token may have reached an error tracker or console output that captures local variables, rotate it.
- Fix `Client#path_for` passing IDs into the request path unencoded. A caller-supplied ID (e.g. `template_id`, `media_id`) could inject a query string or redirect an authenticated request to a different Graph API edge. Segments are now percent-encoded.
- Fix `Webhook::Signature.valid?` raising `TypeError` instead of returning `false` for a `nil` payload.

## [0.3.0] - 2026-08-05

- Add template management: `Whatsapp::MessageTemplates` provides full CRUD over the templates on a WhatsApp Business Account — `create`, `list`, `find`, `update`, `delete`, plus `upsert` for multi-language authentication templates and `create_from_library` for Meta's pre-written library. Templates are built from validated value objects (`Template`, `ComponentSet`, `Component::*`, `Button::*`) that enforce Meta's documented rules — name format, character limits, placeholder/example matching, quick-reply contiguity, carousel structure, limited-time-offer restrictions — before a request is made, so a rejection costs nothing instead of a review cycle. Covers standard, authentication/OTP, carousel, limited-time-offer, and library templates.
- `Whatsapp::Client` now exposes `waba_id`, defaulting from `Whatsapp.configuration`.
- Fix `HTTP::Error: Unknown MIME type: text/javascript` on every API call. The Graph API labels its JSON responses `text/javascript`, which the http gem has no MIME handler for, so inferring the parser from the content type raised instead of parsing. Responses are now parsed as JSON explicitly via `ResponseHandling#parse_json`. Affected `Messages#send!`, all of `Media`, and all of `MessageTemplates`.

## [0.2.0] - 2026-07-31

- Add inbound webhook support: `rake whatsapp:install:webhook` installs a personalizable controller, `Whatsapp::Webhook::Notification.deserialize` parses all 19 documented Meta webhook field types, and `Whatsapp::Webhook::Verification`/`Signature` handle the GET handshake and `X-Hub-Signature-256` check.

## [0.1.0] - 2026-01-15

- Initial release
