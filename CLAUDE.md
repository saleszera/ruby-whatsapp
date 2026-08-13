# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run tests and linting (default)
bundle exec rake

# Tests only
bundle exec rspec

# Run a single spec file — COVERAGE=false is required, or SimpleCov's
# minimum_coverage floor fails the run (exit 2) on the unloaded rest of the gem
COVERAGE=false bundle exec rspec spec/ruby/whatsapp_spec.rb

# Linting
bundle exec rubocop

# Interactive console
bin/console

# Live smoke test against a real WABA (creates and deletes a throwaway template)
WHATSAPP_API_KEY=... WHATSAPP_WABA_ID=... WHATSAPP_PHONE_ID=... bin/dev
```

**Coverage:** SimpleCov is configured in `spec/spec_helper.rb` and must stay above the
`require "ruby/whatsapp"` line — starting it later leaves everything loaded by that
require untracked. Line and branch coverage are both enabled, with floors of 95%/85%
enforced on every full run. The HTML report lands in `coverage/index.html` (gitignored).

Webhook support only becomes active inside a host Rails app — `rake whatsapp:install:webhook` (installs `app/controllers/whatsapp/webhooks_controller.rb`) is not runnable standalone in this repo, since it has no Rails application to install into.

## Architecture

This is a Ruby gem (`ruby-whatsapp`) providing a client for the Meta WhatsApp Cloud API. Auto-loading is handled by Zeitwerk.

**Entry point:** `lib/ruby/whatsapp.rb` — sets up the Zeitwerk loader, exposes `Whatsapp.configure` and `Whatsapp.configuration`.

**Core classes:**

- `Whatsapp::Configuration` — holds `host`, `version`, `api_key`, `phone_id`, `waba_id`. Defaults to `https://graph.facebook.com` / `v24.0`.
- `Whatsapp::Client` — wraps `HTTP.persistent` for connection reuse. Accepts optional instrumentation and timeout. All API requests go through here.
- `Whatsapp::Instrumentation` — middleware-style logger for HTTP requests/responses. Injected into `Client` at initialization.
- `Whatsapp::Messages` — factory class. Accepts `kind` (e.g., `:text`, `:template`), resolves the appropriate subclass via `MessageKinds.const_get(kind.upcase)`, instantiates it, and exposes `send!`.
- `Whatsapp::Media` — handles media upload, URL retrieval, download, and deletion via the API.
- `Whatsapp::MessageTemplates` — full CRUD for the templates on a WhatsApp Business Account (create/list/find/update/delete, plus `upsert` and `create_from_library`). Addresses `waba_id`, not `phone_id`.

**Message class hierarchy:**

```
Messages::Base (ActiveModel::Validations, abstract serialize method)
  ├── Messages::Text
  ├── Messages::Video
  ├── Messages::Template (with Component, Language, Parameter sub-objects)
  ├── Messages::Interactive::Base
  │   ├── ReplyButtons, ListButtons, MediaCarousel, ProductCarousel, UrlButton
  └── [stub classes]: Image, Audio, Document, Contacts, Sticker, Reaction,
                      Address, Location, LocationRequest, MessageWithLink
```

All message classes validate `:to` (recipient phone number) and implement `serialize` to build the API payload hash.

**Response parsing:** `Messages::Response.deserialize` maps the API JSON response into `Response::Contacts` and `Response::Messages` objects.

**Language codes:** `Whatsapp::Utils::LanguageCodes` contains the full list of supported WhatsApp template language codes.

**Template management:** `Whatsapp::MessageTemplates` creates and manages the templates themselves, as opposed to `Messages::Template` which *sends* an already-approved one. See `lib/ruby/whatsapp/message_templates/CLAUDE.md`; in short:

- **These are two different APIs with incompatible component schemas.** Management uses `POST /{WABA_ID}/message_templates` with `text` + `example` and uppercase `HEADER`/`BODY`/`FOOTER`/`BUTTONS`; sending uses `POST /{PHONE_ID}/messages` with `parameters` and lowercase singular types. `Messages::Template::Component` is deliberately *not* reused — only `Utils::LanguageCodes` is shared.
- `Template` / `LibraryTemplate` own template identity; `ComponentSet` owns every rule that spans more than one component (a footer being forbidden alongside a limited-time offer, a carousel implying MARKETING); each `Component`/`Button` class validates only itself. `ComponentSet` is separate so `#update`, which replaces components wholesale without a name or language, can reuse exactly those checks.
- Registry dispatch via frozen `Component::TYPES` / `Button::TYPES` (mirrors `Messages::KINDS`), never `const_get` on caller input. Only component and button types with a published Meta schema are registered.
- Four response shapes, so `Response::{Created,Node,Collection}` rather than one class; `update`/`delete` return a plain boolean. `Response::Node#components` stays raw hashes on purpose — write-side validators must not run over Meta's echoed payloads.
- `docs/template-management-api.md` holds the full API research, including what is deliberately unimplemented (Resumable Upload for media handles, undocumented button/component types) and the four details unverified against a live WABA.

**Webhooks (inbound):** `Whatsapp::Webhook` deserializes Meta's incoming webhook notifications — the opposite direction from everything above. See `lib/ruby/whatsapp/webhook/CLAUDE.md` for the full dispatch-table conventions and field reference; in short:

- `Whatsapp::Webhook::Notification.deserialize(JSON.parse(body))` → `Entry[]` → `Change[]` (`field` + `value`), dispatched through a frozen `FIELDS` registry (mirrors `Messages::KINDS`) to one class per Meta-documented field. Only `messages` has a confirmed schema; the other 18 are best-effort.
- `Whatsapp::Webhook::Verification.call(params:)` / `Whatsapp::Webhook::Signature.valid?(payload:, header:)` handle the GET handshake and the `X-Hub-Signature-256` HMAC check, both defaulting to `Whatsapp.configuration.verify_token`/`app_secret` but overridable per call (for multi-tenant apps with per-account credentials).
- `rake whatsapp:install:webhook` (via `Whatsapp::Railtie`, only active when Rails is loaded) copies a personalizable `app/controllers/whatsapp/webhooks_controller.rb` into the host app using `Whatsapp::Webhook::Installer`.

## Code Principles

- **TDD:** All new features must be driven by tests first. Write the failing spec before implementing any code.
- **SOLID:** Each class has a single responsibility. The message factory, HTTP client, configuration, and instrumentation are deliberately separate. Extend behavior through new classes/modules, not by modifying existing ones.
- **DRY:** Shared validation, serialization patterns, and HTTP behavior live in base classes (`Messages::Base`, `Interactive::Base`) and mixins. Don't repeat payload-building logic across message types.
- **KISS:** Keep implementations straightforward. Stub message classes exist intentionally — implement only what the API requires, nothing speculative.
- **YARD:** Comments on methods and attributes use YARD tags (`@param`, `@return`, `@raise`, `@example`) rather than plain prose — see `response_handling.rb` or `configuration.rb` for the established shape. A one-line description above the tags is fine when the WHY isn't obvious; the tags carry the mechanical detail.

## Key Details

- Ruby version: 3.4.7 (`.ruby-version`)
- RuboCop config inherits from `rubocop-basic`; complexity cops (ABC, Cyclomatic, etc.) are disabled
- Tests use RSpec with Faker and WebMock (`WebMock.disable_net_connect!` — every HTTP interaction must be stubbed). No Factory Bot or Shoulda Matchers; write plain `let`/`subject` specs with `stub_request`
- CI runs `bundle exec rake` (tests + linting) on Ruby 3.2.2 via GitHub Actions
- Many message types are stubs — only `Text`, `Video`, `Template`, and `Interactive` variants have full implementations
