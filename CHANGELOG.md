## [Unreleased]

- Add inbound webhook support: `rake whatsapp:install:webhook` installs a personalizable controller, `Whatsapp::Webhook::Notification.deserialize` parses all 19 documented Meta webhook field types, and `Whatsapp::Webhook::Verification`/`Signature` handle the GET handshake and `X-Hub-Signature-256` check.

## [0.1.0] - 2026-01-15

- Initial release
