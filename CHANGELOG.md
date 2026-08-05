## [Unreleased]

## [0.3.0] - 2026-08-05

- Add template management: `Whatsapp::MessageTemplates` provides full CRUD over the templates on a WhatsApp Business Account — `create`, `list`, `find`, `update`, `delete`, plus `upsert` for multi-language authentication templates and `create_from_library` for Meta's pre-written library. Templates are built from validated value objects (`Template`, `ComponentSet`, `Component::*`, `Button::*`) that enforce Meta's documented rules — name format, character limits, placeholder/example matching, quick-reply contiguity, carousel structure, limited-time-offer restrictions — before a request is made, so a rejection costs nothing instead of a review cycle. Covers standard, authentication/OTP, carousel, limited-time-offer, and library templates.
- `Whatsapp::Client` now exposes `waba_id`, defaulting from `Whatsapp.configuration`.
- Fix `HTTP::Error: Unknown MIME type: text/javascript` on every API call. The Graph API labels its JSON responses `text/javascript`, which the http gem has no MIME handler for, so inferring the parser from the content type raised instead of parsing. Responses are now parsed as JSON explicitly via `ResponseHandling#parse_json`. Affected `Messages#send!`, all of `Media`, and all of `MessageTemplates`.

## [0.2.0] - 2026-07-31

- Add inbound webhook support: `rake whatsapp:install:webhook` installs a personalizable controller, `Whatsapp::Webhook::Notification.deserialize` parses all 19 documented Meta webhook field types, and `Whatsapp::Webhook::Verification`/`Signature` handle the GET handshake and `X-Hub-Signature-256` check.

## [0.1.0] - 2026-01-15

- Initial release
