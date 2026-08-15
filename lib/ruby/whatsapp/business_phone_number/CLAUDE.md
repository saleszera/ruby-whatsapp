# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory wraps the registration switch for a single business phone number: the
prerequisite that makes every other Cloud API endpoint in this gem work for that number
at all — sending (`../messages/`), media (`../media.rb`), templates
(`../message_templates/`). It is unrelated to `../subscribed_app/`, which turns
*webhook delivery* on and off for a whole WhatsApp Business Account; this module is
per phone number and has nothing to do with notifications.

Source:
- https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
- https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-deregister-api

Full API research and design rationale: see the Meta docs links above.

## Why this follows `SubscribedApp`, with two exceptions

`Whatsapp::SubscribedApp` is the closest sibling: a small set of independent
account-admin actions on one edge, one class per action, each a stateless `.call`. This
module follows that shape, but diverges in two places where the actual API differs from
`subscribed_apps`:

1. **One `Response` class, not a `Response::` namespace.** `register` and `deregister`
   both return the identical `{"success": true}`. `SubscribedApp` needed three response
   classes because its three actions genuinely return different shapes; splitting one
   shape into two classes here would be ceremony with no payoff.
2. **`Register` and `Deregister` are validated instances with a public `#serialize`,
   not pure class methods.** `SubscribedApp`'s actions have nothing to validate.
   `register` does — Meta documents a 6-digit PIN and a closed set of 14 region codes —
   and this gem's standing principle is to raise locally rather than round-trip a
   known-bad payload, doubly so here since a rejected attempt still counts against the
   10-request/72-hour rate limit. So both classes take the `Messages::Base` /
   `MessageTemplates::Template` shape (`ActiveModel::Validations`, `validate!` at the
   end of `initialize`, a `#serialize` building the payload) and add a class-level
   `.call` for the request itself. `Deregister` has no attributes, and therefore no
   `ActiveModel::Validations` — nothing to validate.

## Architecture

```
BusinessPhoneNumber              module doc + Error (Whatsapp::BusinessPhoneNumber::Error)
  ├── Transport                  shared: edge_path(client, action), phone_id guard
  ├── Register                   POST /{phone_id}/register    -> Response
  ├── Deregister                 POST /{phone_id}/deregister  -> Response
  └── Response                   {success}
```

`Transport` is `extend`ed (not `include`d) by both action classes, mirroring
`SubscribedApp::Transport`. Addresses `client.phone_id`, like `Media` and `Messages` —
not `waba_id`.

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
4. `Register`'s PIN is a credential: `#inspect` redacts it (`pin=[REDACTED]`), the same
   as `Client#inspect`/`Configuration#inspect` redact `api_key`/`app_secret`, and the
   validation error message never echoes it either.
5. `DataLocalizationRegions` (Register's enum of the 14 supported region codes) nests
   inside `Register` rather than living in its own file, since it has exactly one
   consumer — following `MessageTemplates::Template::SubCategories`'s precedent, not
   `MessageTemplates::Categories`'s (which is shared by three classes). `.normalize`
   accepts either casing and emits uppercase, per the enum convention in
   `../message_templates/CLAUDE.md`.

## Reference

| Method | Request | Returns |
|---|---|---|
| `Register.call(pin:, data_localization_region:)` | `POST /{phone_id}/register` | `Response` |
| `Deregister.call` | `POST /{phone_id}/deregister` | `Response` |

Both require `phone_id` (set via `Whatsapp.configure` or `Client.new(phone_id:)`) and
the `whatsapp_business_messaging` + `whatsapp_business_management` permissions.

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
Whatsapp::BusinessPhoneNumber::Register.new(pin: "212834", data_localization_region: "CH").serialize
# => { messaging_product: "whatsapp", pin: "212834", data_localization_region: "CH" }

Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834")
# => #<Whatsapp::BusinessPhoneNumber::Response success=true>

Whatsapp::BusinessPhoneNumber::Deregister.call
# => #<Whatsapp::BusinessPhoneNumber::Response success=true>
```

## Not implemented

- **Client-side rate-limit tracking.** Both edges cap at 10 requests per business
  number per 72-hour moving window (error `133016` past it) — server-side state this
  gem cannot observe. Surfacing that error via `handle_response!` is the whole of the
  handling.
- **Two-step verification PIN management.** `register` consumes an existing PIN;
  setting or changing one is a different, undocumented-here endpoint.
- **A `bin/dev` smoke test.** Unlike the throwaway template the existing smoke flow
  creates and deletes, registering or deregistering a real number is destructive and
  rate-limited.

## Adding a new field (checklist)

- [ ] Confirm Meta actually publishes it for this edge.
- [ ] Write the failing spec under `spec/ruby/whatsapp/business_phone_number/...`
- [ ] Add the attribute to `Register` (or `Response`), with a `# @!attribute` tag and
      any validation Meta documents as a client-side rule
- [ ] Thread it through `Register.call`/`#serialize`
- [ ] Add a row/example to this file and to `docs/business-phone-number-api.md`
- [ ] `bundle exec rake` green before committing
