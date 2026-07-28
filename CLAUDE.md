# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run tests and linting (default)
bundle exec rake

# Tests only
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/ruby/whatsapp_spec.rb

# Linting
bundle exec rubocop

# Interactive console
bin/console
```

## Architecture

This is a Ruby gem (`ruby-whatsapp`) providing a client for the Meta WhatsApp Cloud API. Auto-loading is handled by Zeitwerk.

**Entry point:** `lib/ruby/whatsapp.rb` — sets up the Zeitwerk loader, exposes `Whatsapp.configure` and `Whatsapp.configuration`.

**Core classes:**

- `Whatsapp::Configuration` — holds `host`, `version`, `api_key`, `phone_id`, `waba_id`. Defaults to `https://graph.facebook.com` / `v24.0`.
- `Whatsapp::Client` — wraps `HTTP.persistent` for connection reuse. Accepts optional instrumentation and timeout. All API requests go through here.
- `Whatsapp::Instrumentation` — middleware-style logger for HTTP requests/responses. Injected into `Client` at initialization.
- `Whatsapp::Messages` — factory class. Accepts `kind` (e.g., `:text`, `:template`), resolves the appropriate subclass via `MessageKinds.const_get(kind.upcase)`, instantiates it, and exposes `send!`.
- `Whatsapp::Media` — handles media upload, URL retrieval, download, and deletion via the API.

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

## Code Principles

- **TDD:** All new features must be driven by tests first. Write the failing spec before implementing any code.
- **SOLID:** Each class has a single responsibility. The message factory, HTTP client, configuration, and instrumentation are deliberately separate. Extend behavior through new classes/modules, not by modifying existing ones.
- **DRY:** Shared validation, serialization patterns, and HTTP behavior live in base classes (`Messages::Base`, `Interactive::Base`) and mixins. Don't repeat payload-building logic across message types.
- **KISS:** Keep implementations straightforward. Stub message classes exist intentionally — implement only what the API requires, nothing speculative.

## Key Details

- Ruby version: 3.4.7 (`.ruby-version`)
- RuboCop config inherits from `rubocop-basic`; complexity cops (ABC, Cyclomatic, etc.) are disabled
- Tests use RSpec with Factory Bot, WebMock, and Shoulda Matchers
- CI runs `bundle exec rake` (tests + linting) on Ruby 3.2.2 via GitHub Actions
- Many message types are stubs — only `Text`, `Video`, `Template`, and `Interactive` variants have full implementations
