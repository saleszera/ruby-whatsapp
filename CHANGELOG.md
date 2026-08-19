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
