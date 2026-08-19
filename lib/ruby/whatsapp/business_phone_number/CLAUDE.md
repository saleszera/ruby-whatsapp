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

Alongside that flow, two sub-namespaces describe things *about* the number rather than its
onboarding state:

- `Profile` reads and updates the business profile a WhatsApp user sees — the public card:
  about line, description, address, email, websites, vertical, picture. Addresses
  `phone_id`, exactly like the onboarding actions.
- `Account` reads and updates the WhatsApp Business Account the number belongs to — the one
  part of this directory that addresses `waba_id` rather than `phone_id`.

See "Why `Account` and `Profile` live here" below.

Source:
- https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-deregister-api
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-verification-request-code-api
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/verify-code-api
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/whatsapp-business-account-api
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/whatsapp-business-profile-api

Full API research and design rationale: see the Meta docs links above.

## Why this follows `SubscribedApp`, with two exceptions

`Whatsapp::SubscribedApp` is the closest sibling: a small set of independent
account-admin actions on one edge, one class per action, each a stateless `.call`. This
module follows that shape, but diverges in two places where the actual API differs from
`subscribed_apps`:

1. **One `Response` class, not a `Response::` namespace.** Every write action returns the
   same `{"success": true}` shape — the four onboarding ones, `Account::Update`, and
   `Profile::Update` (`VerifyCode` additionally an optional `id`).
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
  ├── Transport                  shared: edge_path(client, action); guard via Whatsapp::PathBuilding
  ├── RequestCode                POST /{phone_id}/request_code -> Response
  ├── VerifyCode                 POST /{phone_id}/verify_code  -> Response
  ├── Register                   POST /{phone_id}/register     -> Response
  ├── Deregister                 POST /{phone_id}/deregister    -> Response
  ├── Response                   {success, id?}
  ├── Profile                    the profile a user sees — phone_id, via the SAME Transport
  │     ├── Get                  GET  /{phone_id}/whatsapp_business_profile -> Profile::Details
  │     ├── Update               POST /{phone_id}/whatsapp_business_profile -> Response
  │     ├── Details              messaging_product, about, address, description, email,
  │     │                        profile_picture_url, websites, vertical
  │     └── Verticals            the 21-value enum, shared by Update and Details
  └── Account                    the WABA node — waba_id, not phone_id
        ├── Transport            node_path(client), waba_id, NO edge segment
        ├── Get                  GET  /{waba_id}  -> Account::Details
        ├── Update               POST /{waba_id}  -> Response
        └── Details              id, name, timezone_id, statuses, ownership, ...
```

`Transport` is `extend`ed (not `include`d) by all four onboarding action classes **and by
`Profile::Get`/`Profile::Update`**, mirroring `SubscribedApp::Transport`. Addresses
`client.phone_id`, like `Media` and `Messages`. There are only two transports in this
directory — `Profile` needed none, since its endpoint is a phone-number-scoped *edge*, which
is exactly what `edge_path` already builds. Both transports `include`
`Whatsapp::PathBuilding` (`../path_building.rb`), the gem-wide mixin owning the guard and
its wording.

## Why `Account` and `Profile` live here

Both describe something *about* a phone number rather than its onboarding state, which is why they sit here. They are **not** the same kind of case, and the difference is worth keeping straight:

| | Addresses | Own transport? |
|---|---|---|
| onboarding actions | `phone_id` + edge | no — `Transport#edge_path` |
| `Profile` | `phone_id` + edge | **no** — reuses the very same `edge_path` |
| `Account` | `waba_id`, no edge | yes — `Account::Transport#node_path` |

### `Account`

It is a deliberate exception, not an accident. `Account` wraps the WABA **node**
(`GET`/`POST /{waba_id}`), and every other WABA-scoped feature in this gem is its own
top-level module (`MessageTemplates`, `SubscribedApp`). It sits here because it
describes the account a phone number belongs to, and that placement was an explicit
call. Two consequences worth knowing before touching this directory:

1. **Two transports, deliberately.** `BusinessPhoneNumber::Transport#edge_path(client,
   action)` addresses `phone_id` and always appends an edge segment; the node endpoint
   needs neither. `Account::Transport#node_path(client)` addresses `waba_id` with no
   extra segment. Since both now delegate the guard and its message to
   `Whatsapp::PathBuilding`, each file is down to one `scoped_path` call and the naming
   *is* the point: `node_path` vs `edge_path` keeps the two from being confused at a call
   site, even though `Account::Transport` shadows the outer `Transport` by lexical scope
   inside `module Account`. Do not collapse them into one method with an optional
   segment — that would put an edge and a node behind the same name.
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

### `Profile`

It sits here because a business profile describes how a *phone number* presents itself — the
same reason `Account` does. Unlike `Account`, though, it is **not** an exception to anything:
Meta exposes the profile as an edge on the phone number
(`GET`/`POST /{phone_id}/whatsapp_business_profile`), so it addresses the ID this module
already addresses and reuses `Transport#edge_path` untouched. Adding a third transport, or
reaching for a caller-supplied ID, would both be wrong here.

Two things about it are worth knowing:

1. **`Profile::Details` owns the `data` envelope.** Meta's reference documents the read as
   `{"data": [{"business_profile": {...}}]}`, while live responses are observed to carry the
   profile fields directly in `data[0]`. `Details.deserialize` reads **both** rather than
   betting on one, and takes the whole parsed body so the envelope knowledge lives in one
   place. That follows this gem's habit of flattening meaningless wrapper levels —
   `SubscribedApp::Response::App` flattens `whatsapp_business_api_data`,
   `MessageTemplates::Response::Paging` flattens `paging.cursors`. Only the first entry is
   read: a phone number has exactly one profile.
2. **`Profile::Update` reuses `BusinessPhoneNumber::Response`**, for the same reason
   `Account::Update` does — the endpoint answers a bare `{success}`. Write it out as
   `BusinessPhoneNumber::Response` at the call site; bare `Response` resolving up two
   lexical scopes is too subtle. `Get` gets its own `Details` because the shape is genuinely
   different. Note this endpoint does **not** return an `id`, so `Response#id` stays
   `VerifyCode`-only.

`Profile::Verticals` is the one enum in this directory with its own file. Two consumers —
`Update` validates against it, `Details` documents its raw value against it — so it follows
`MessageTemplates::Categories`' precedent rather than `Register::DataLocalizationRegions`',
per convention 5 below.

## Conventions

Same as `../subscribed_app/CLAUDE.md` unless noted:

1. `Response.deserialize(data)`: `data ||= {}` first, tolerant of a nil or partial
   payload, exactly like every other `Response#deserialize` in this gem.
2. `success` is computed as `response["success"] == true` — a strict boolean, the same
   convention as `SubscribedApp::Response::Unsubscription`, `MessageTemplates#success?`
   and `Media#delete`.
3. Each action class raises `Whatsapp::BusinessPhoneNumber::Error` (via a transport's path
   guard for a missing ID, or `ResponseHandling#handle_response!` for a failed request) —
   never the generic `Whatsapp::RequestError`. `Account` and `Profile` reuse the module's own
   `Error` rather than declaring their own, so one `rescue` still covers the whole directory.
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
   `../message_templates/CLAUDE.md`. `Profile::Verticals` is the one enum here with its own
   file, because it has two consumers — see "Why `Account` and `Profile` live here" above.
6. **Validate only what Meta documents, nothing speculative.** `Register`'s `pin` gets a
   `/\A\d{6}\z/` format check because Meta documents it as 6-digit; `VerifyCode`'s
   `code` and `RequestCode`'s `language` get presence only, because Meta documents both
   as plain `string` with no format or enum. `language` is deliberately **not**
   validated against `Utils::LanguageCodes` — that list belongs to the template API
   (locale codes Meta *approves*), and this field is closer to a delivery-preference
   locale than a template's `language`. `Profile::Update` follows the same line: the vertical
   enum and Meta's documented character/count limits are enforced, but `email`'s *format* is
   not — Meta validates addresses server-side, and a regex here would reject valid exotic
   ones, the same standing decision as `override_callback_uri` in `../subscribed_app/`.
7. **Write-side `nil` means "leave alone", not "blank it".** `Profile::Update#serialize` and
   `Account::Update#serialize` both `.compact`, since Meta reads an explicit `null` as an
   instruction to clear the field. `Profile::Update` has one deliberate exception: an empty
   `websites` array survives compaction, because that *is* how the list is cleared — and it
   therefore also satisfies the "change something" guard.

## Reference

| Method | Request | Returns |
|---|---|---|
| `RequestCode.call(code_method:, language:)` | `POST /{phone_id}/request_code` | `Response` |
| `VerifyCode.call(code:)` | `POST /{phone_id}/verify_code` | `Response` (may carry `id`) |
| `Register.call(pin:, data_localization_region:)` | `POST /{phone_id}/register` | `Response` |
| `Deregister.call` | `POST /{phone_id}/deregister` | `Response` |
| `Account::Get.call(fields:)` | `GET /{waba_id}` | `Account::Details` |
| `Account::Update.call(name:, timezone_id:)` | `POST /{waba_id}` | `Response` |
| `Profile::Get.call(fields:)` | `GET /{phone_id}/whatsapp_business_profile` | `Profile::Details` |
| `Profile::Update.call(**fields)` | `POST /{phone_id}/whatsapp_business_profile` | `Response` |

The four onboarding actions and the two `Profile` actions require `phone_id` (set via
`Whatsapp.configure` or `Client.new(phone_id:)`) and the `whatsapp_business_messaging` +
`whatsapp_business_management` permissions. The two `Account` actions require `waba_id`
instead, and only `whatsapp_business_management`.

`Account::Get` and `Profile::Get` send no `fields` param when none is given, so Meta returns
its own defaults — matching `SubscribedApp::List`. `Fields::ALL` is offered for
convenience but is **not** used to validate caller input: a field Meta adds later must
work without a gem release. `Account::Details` keeps every status as a raw string for
the same reason, with `ReviewStatuses`/`VerificationStatuses`/`OwnershipTypes`
constants and `#approved?`/`#verified?`/`#self_owned?` predicates for comparison only;
`Profile::Details` keeps `vertical` raw for the same reason, with `Verticals::ALL` to
compare against.

`Profile::Update#serialize` always sends `messaging_product: "whatsapp"` and compacts away
every field not given. Its documented limits are about 139, address 256, description 512,
and email 128 characters, plus at most 2 websites.

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

Whatsapp::BusinessPhoneNumber::Profile::Update.new(vertical: "retail", websites: []).serialize
# => { messaging_product: "whatsapp", vertical: "RETAIL", websites: [] }
```

### Unverified against a live WABA

`Account`'s specs are built from Meta's published schema, not a live account. Confirm
and record here when someone has a real WABA to hand:

- whether `POST /{waba_id}` really answers a bare `{success}` rather than echoing the node
- whether `timezone_id` is a numeric string (`"1"`) or an IANA name
- whether an unrecognized `fields` entry 400s or is silently ignored
- whether `primary_business_location` is a plain string or a nested object

`Profile`'s specs are likewise built from Meta's published schema. The first item is the one
genuinely load-bearing uncertainty in the feature:

- **which shape the read envelope actually takes.** Meta's reference declares the `data`
  entry as `{"business_profile": {...}}`, but live responses are widely observed to put the
  profile fields directly in `data[0]`. `Profile::Details.deserialize` reads both, so either
  answer works — but if a live account settles it, simplify `unwrap` and say so here.
- whether the character limits (about 139, address 256, description 512, email 128, 2
  websites) are enforced by *this* edge or only by the separate profile node endpoint. They
  are validated client-side either way, since a local rejection costs nothing.
- whether `POST` ever echoes anything beyond `{success}`. The reference says it does not, so
  `Response#id` stays `VerifyCode`-only.

## Not implemented

- **Client-side rate-limit tracking.** `register`/`deregister` document a hard cap (10
  requests per business number per 72-hour moving window, error `133016` past it);
  `request_code`/`verify_code` document only "standard Graph API rate limits ...
  additional rate limiting may be enforced" with no published number. Either way this
  is server-side state the gem cannot observe — surfacing the error via
  `handle_response!` is the whole of the handling.
- **Two-step verification PIN management.** `register` consumes an existing PIN;
  setting or changing one is a different, undocumented-here endpoint.
- **Resumable Upload API.** `Profile::Update` accepts and forwards `profile_picture_handle`
  as an opaque string, but the endpoint that mints one is not wrapped. `Media#upload` returns
  a media ID, which is a different thing and will not work here. Same standing exclusion as
  media handles in `../message_templates/CLAUDE.md`.
- **Profile read caching.** Meta suggests it; invalidation is an application concern.
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
      (or `account.md` / `profile.md` for an `Account` / `Profile` field)
- [ ] `bundle exec rake` green before committing
