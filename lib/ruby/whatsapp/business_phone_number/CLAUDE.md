# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory wraps a business phone number's whole onboarding-and-deboarding path
with Cloud API — the prerequisite that makes every other endpoint in this gem work for
that number at all: sending (`../messages/`), media (`../media.rb`), templates
(`../message_templates/`). It is unrelated to `../subscribed_app/`, which turns
*webhook delivery* on and off for a whole WhatsApp Business Account; this module is
per phone number and has nothing to do with notifications.

The full flow, in order:

```
RequestCode  ->  VerifyCode  ->  Register            (onboarding)
(send OTP)       (confirm it)    (activate on Cloud API)

Deregister                                            (the reverse switch)
```

Alongside that flow, `Account` reads and updates the WhatsApp Business Account the
number belongs to — the one part of this directory that addresses `waba_id` rather than
`phone_id`. See "Why `Account` lives here" below.

Source:
- https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-deregister-api
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-verification-request-code-api
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/verify-code-api
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/whatsapp-business-account-api

Full API research and design rationale: see the Meta docs links above.

## Why this follows `SubscribedApp`, with two exceptions

`Whatsapp::SubscribedApp` is the closest sibling: a small set of independent
account-admin actions on one edge, one class per action, each a stateless `.call`. This
module follows that shape, but diverges in two places where the actual API differs from
`subscribed_apps`:

1. **One `Response` class, not a `Response::` namespace.** All four actions return the
   same `{"success": true}` shape (`VerifyCode` additionally an optional `id`).
   `SubscribedApp` needed three response classes because its three actions genuinely
   return different shapes; splitting one shape into several classes here would be
   ceremony with no payoff.
2. **Every action is a validated instance with a public `#serialize`, not a pure class
   method.** `SubscribedApp`'s actions have nothing to validate. Three of these four
   do — Meta documents a 6-digit PIN and 14 region codes for `register`, a closed set
   of delivery methods for `request_code` — and this gem's standing principle is to
   raise locally rather than round-trip a known-bad payload, doubly so here since a
   rejected attempt still counts against the rate limit each edge documents. So each
   class takes the `Messages::Base` / `MessageTemplates::Template` shape
   (`ActiveModel::Validations`, `validate!` at the end of `initialize`, a `#serialize`
   building the payload) and adds a class-level `.call` for the request itself.
   `Deregister` is the one exception: no attributes, and therefore no
   `ActiveModel::Validations` — nothing to validate.

## Architecture

```
BusinessPhoneNumber              module doc + Error (Whatsapp::BusinessPhoneNumber::Error)
  ├── Transport                  shared: edge_path(client, action), phone_id guard
  ├── RequestCode                POST /{phone_id}/request_code -> Response
  ├── VerifyCode                 POST /{phone_id}/verify_code  -> Response
  ├── Register                   POST /{phone_id}/register     -> Response
  ├── Deregister                 POST /{phone_id}/deregister    -> Response
  ├── Response                   {success, id?}
  └── Account                    the WABA node — waba_id, not phone_id
        ├── Transport            node_path(client), waba_id guard, NO edge segment
        ├── Get                  GET  /{waba_id}  -> Account::Details
        ├── Update               POST /{waba_id}  -> Response
        └── Details              id, name, timezone_id, statuses, ownership, ...
```

`Transport` is `extend`ed (not `include`d) by all four onboarding action classes,
mirroring `SubscribedApp::Transport`. Addresses `client.phone_id`, like `Media` and
`Messages`.

## Why `Account` lives here

It is a deliberate exception, not an accident. `Account` wraps the WABA **node**
(`GET`/`POST /{waba_id}`), and every other WABA-scoped feature in this gem is its own
top-level module (`MessageTemplates`, `SubscribedApp`). It sits here because it
describes the account a phone number belongs to, and that placement was an explicit
call. Two consequences worth knowing before touching this directory:

1. **Two transports, deliberately.** `BusinessPhoneNumber::Transport#edge_path(client,
   action)` guards `phone_id` and always appends an edge segment; the node endpoint
   needs neither. `Account::Transport#node_path(client)` guards `waba_id` and calls
   `client.path_for(client.waba_id)` with no extra segment. The methods are named
   differently on purpose — `node_path` vs `edge_path` — so the two can never be
   confused at a call site, even though `Account::Transport` shadows the outer
   `Transport` by lexical scope inside `module Account`.
2. **`Account::Update` reuses `BusinessPhoneNumber::Response`.** The endpoint answers
   with a bare `{"success": true}` — exactly the shape the existing class already
   models, and exactly the case its one-class-for-all rationale was written for. Write
   it explicitly as `BusinessPhoneNumber::Response` at the call site; bare `Response`
   resolving up two lexical scopes is too subtle to leave implicit. `Get` gets its own
   `Details` class because the node shape is genuinely different.

`Get`, unlike the onboarding actions, is a pure class method with no
`ActiveModel::Validations` — a read with nothing to validate, matching
`SubscribedApp::List`. `Update` is a validated instance, because Meta documents `name`
as non-empty and both fields are optional, so an all-nil call would spend a request to
change nothing.

## Conventions

Same as `../subscribed_app/CLAUDE.md` unless noted:

1. `Response.deserialize(data)`: `data ||= {}` first, tolerant of a nil or partial
   payload, exactly like every other `Response#deserialize` in this gem.
2. `success` is computed as `response["success"] == true` — a strict boolean, the same
   convention as `SubscribedApp::Response::Unsubscription`, `MessageTemplates#success?`
   and `Media#delete`.
3. Each action class raises `Whatsapp::BusinessPhoneNumber::Error` (via
   `Transport#edge_path` for a missing `phone_id`, or `ResponseHandling#handle_response!`
   for a failed request) — never the generic `Whatsapp::RequestError`.
4. Credentials in transit are redacted in `#inspect` — `Register`'s PIN
   (`pin=[REDACTED]`) and `VerifyCode`'s OTP (`code=[REDACTED]`) — the same as
   `Client#inspect`/`Configuration#inspect` redact `api_key`/`app_secret`, and neither
   validation error message ever echoes the raw value.
5. Single-consumer enums nest inside the class that uses them rather than living in
   their own file — `Register::DataLocalizationRegions` (14 region codes) and
   `RequestCode::CodeMethods` (`SMS`/`VOICE`) both follow
   `MessageTemplates::Template::SubCategories`'s precedent, not
   `MessageTemplates::Categories`'s (which is shared by three classes). Each `.normalize`
   accepts either casing and emits uppercase, per the enum convention in
   `../message_templates/CLAUDE.md`.
6. **Validate only what Meta documents, nothing speculative.** `Register`'s `pin` gets a
   `/\A\d{6}\z/` format check because Meta documents it as 6-digit; `VerifyCode`'s
   `code` and `RequestCode`'s `language` get presence only, because Meta documents both
   as plain `string` with no format or enum. `language` is deliberately **not**
   validated against `Utils::LanguageCodes` — that list belongs to the template API
   (locale codes Meta *approves*), and this field is closer to a delivery-preference
   locale than a template's `language`.

## Reference

| Method | Request | Returns |
|---|---|---|
| `RequestCode.call(code_method:, language:)` | `POST /{phone_id}/request_code` | `Response` |
| `VerifyCode.call(code:)` | `POST /{phone_id}/verify_code` | `Response` (may carry `id`) |
| `Register.call(pin:, data_localization_region:)` | `POST /{phone_id}/register` | `Response` |
| `Deregister.call` | `POST /{phone_id}/deregister` | `Response` |
| `Account::Get.call(fields:)` | `GET /{waba_id}` | `Account::Details` |
| `Account::Update.call(name:, timezone_id:)` | `POST /{waba_id}` | `Response` |

The four onboarding actions require `phone_id` (set via `Whatsapp.configure` or
`Client.new(phone_id:)`) and the `whatsapp_business_messaging` +
`whatsapp_business_management` permissions. The two `Account` actions require `waba_id`
instead, and only `whatsapp_business_management`.

`Account::Get` sends no `fields` param when none is given, so Meta returns its own
defaults (`id`, `name`) — matching `SubscribedApp::List`. `Fields::ALL` is offered for
convenience but is **not** used to validate caller input: a field Meta adds later must
work without a gem release. `Account::Details` keeps every status as a raw string for
the same reason, with `ReviewStatuses`/`VerificationStatuses`/`OwnershipTypes`
constants and `#approved?`/`#verified?`/`#self_owned?` predicates for comparison only.

`RequestCode#serialize` always sends both `code_method` (`"SMS"` or `"VOICE"`) and
`language` — both documented required, so neither is compacted away.
`Register#serialize` always sends `messaging_product: "whatsapp"` and the `pin`;
`data_localization_region` (one of `AU ID IN JP SG KR DE CH GB BR BH ZA AE CA`) is
included only when given.

### To target a number other than the configured `phone_id`

Inject a client, the same idiom `SubscribedApp` uses for `waba_id`:

```ruby
Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834", client: Whatsapp::Client.new(phone_id: "OTHER_ID"))
```

### Verified examples

```ruby
Whatsapp::BusinessPhoneNumber::RequestCode.call(code_method: "SMS", language: "en_US").success
# => true

result = Whatsapp::BusinessPhoneNumber::VerifyCode.call(code: "123456")
result.success   # => true
result.id        # => "106540352242922"

Whatsapp::BusinessPhoneNumber::Register.new(pin: "212834", data_localization_region: "CH").serialize
# => { messaging_product: "whatsapp", pin: "212834", data_localization_region: "CH" }

Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834").success
# => true

Whatsapp::BusinessPhoneNumber::Deregister.call.success
# => true
```

### Unverified against a live WABA

`Account`'s specs are built from Meta's published schema, not a live account. Confirm
and record here when someone has a real WABA to hand:

- whether `POST /{waba_id}` really answers a bare `{success}` rather than echoing the node
- whether `timezone_id` is a numeric string (`"1"`) or an IANA name
- whether an unrecognized `fields` entry 400s or is silently ignored
- whether `primary_business_location` is a plain string or a nested object

## Not implemented

- **Client-side rate-limit tracking.** `register`/`deregister` document a hard cap (10
  requests per business number per 72-hour moving window, error `133016` past it);
  `request_code`/`verify_code` document only "standard Graph API rate limits ...
  additional rate limiting may be enforced" with no published number. Either way this
  is server-side state the gem cannot observe — surfacing the error via
  `handle_response!` is the whole of the handling.
- **Two-step verification PIN management.** `register` consumes an existing PIN;
  setting or changing one is a different, undocumented-here endpoint.
- **A `bin/dev` smoke test.** Unlike the throwaway template the existing smoke flow
  creates and deletes, exercising this flow against a real number is destructive and
  rate-limited.

## Adding a new field (checklist)

- [ ] Confirm Meta actually publishes it for this edge.
- [ ] Write the failing spec under `spec/ruby/whatsapp/business_phone_number/...`
- [ ] Add the attribute to the relevant action class (or `Response`), with a
      `# @!attribute` tag and any validation Meta documents as a client-side rule
- [ ] Thread it through that class's `.call`/`#serialize`
- [ ] Add a row/example to this file and to `docs/business_phone_number/README.md`
      (or `docs/business_phone_number/account.md` for an `Account` field)
- [ ] `bundle exec rake` green before committing
