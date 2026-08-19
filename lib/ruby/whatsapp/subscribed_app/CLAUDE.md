# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory wraps the `subscribed_apps` edge of a WhatsApp Business Account: the
switch that turns webhook delivery on or off. It has no relation to `../webhook/`,
which only deserializes notifications once Meta is already sending them — this is what
makes that sending happen in the first place.

Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api

## Why one class per action, not one class with several methods

`Whatsapp::MessageTemplates` is one class with `create`/`list`/`find`/`update`/`delete`
because those verbs share a concept (a template has an identity, a set of cross-field
validation rules, etc.) that benefits from living together. `subscribed_apps` has no
such shared concept — subscribing, listing, and unsubscribing are three independent,
unrelated actions on the same edge. Splitting them into `List`, `Subscribe`, and
`Unsubscribe` mirrors `Webhook::Verification`/`Webhook::Signature` instead: small,
single-responsibility classes, each a stateless class-level `.call`.

## Architecture

```
SubscribedApp                    module doc + Error (Whatsapp::SubscribedApp::Error)
  ├── Transport                  shared: edge_path(client); guard via Whatsapp::PathBuilding
  ├── List                       GET    -> Response::Collection
  ├── Subscribe                  POST   -> Response::Subscription
  ├── Unsubscribe                DELETE -> Response::Unsubscription
  └── Response
        ├── App                  one subscribed app: id, name, link, override_callback_uri
        ├── Collection           {data: [App]}, Enumerable            (List)
        ├── Subscription         {success, data: [App]}, Enumerable   (Subscribe)
        └── Unsubscription       {success}                            (Unsubscribe)
```

`Transport` is `extend`ed (not `include`d) by all three action classes, since they
expose no instance state — just class methods, same as `ResponseHandling` is also
`extend`ed here rather than `include`d (mirroring how `Whatsapp::Messages` `extend`s it
for its own class-level `mark_message_as_read!`).

`Transport` itself `include`s `Whatsapp::PathBuilding`, the gem-wide mixin holding the
`waba_id`/`phone_id` guard and its wording (`../path_building.rb`). What stays here is
only the edge this module addresses; the message it raises is unchanged.

### No shared response base class

`Collection`, `Subscription`, and `Unsubscription` diverge enough (`data`-only,
`success`+`data`, `success`-only) that an inheritance hierarchy would force fields onto
classes that don't have them. Composition is the DRY lever instead: `Collection` and
`Subscription` both build `Response::App` from the same `data` array shape, and
`Subscription.deserialize` reuses `Collection.deserialize(response).to_a` rather than
duplicating that mapping. This mirrors how `MessageTemplates::Response::Collection`
already composes `Paging`/`Summary` rather than subclassing them.

## Conventions

Same as `../message_templates/CLAUDE.md` and `../webhook/CLAUDE.md` unless noted:

1. Every `Response::*` class follows the gem's `.deserialize(data)` convention:
   `data ||= {}` first, `Array(data["key"]).map { ... }` for lists (never bare
   `data["key"].map`), tolerant of a nil or partial payload.
2. `success` is computed as `response["success"] == true` — a strict boolean, matching
   `MessageTemplates#success?`/`Media#delete`'s existing convention for an
   actionable/branch-worthy flag. This differs from `Messages::Response#success`, which
   passes the raw value through unchanged; that field is optional and only meaningful
   for a couple of message kinds, whereas here `success` is the primary thing every
   caller of `Subscribe`/`Unsubscribe` branches on.
3. Each action class raises `Whatsapp::SubscribedApp::Error` (via `Transport#edge_path`
   for a missing `waba_id`, or `ResponseHandling#handle_response!` for a failed
   request) — never the generic `Whatsapp::RequestError`, mirroring
   `MessageTemplates::TemplateError`/`Media::MediaError`.

## Reference

| Method | Request | Returns |
|---|---|---|
| `List.call(client:, fields:)` | `GET /{waba_id}/subscribed_apps` | `Response::Collection` |
| `Subscribe.call(client:, override_callback_uri:, verify_token:)` | `POST /{waba_id}/subscribed_apps` | `Response::Subscription` |
| `Unsubscribe.call(client:)` | `DELETE /{waba_id}/subscribed_apps` | `Response::Unsubscription` |

All three require `waba_id` (set via `Whatsapp.configure` or `Client.new(waba_id:)`) and
the `whatsapp_business_management` permission. No pagination is documented for this
edge — an account typically has very few subscribed apps.

`override_callback_uri`/`verify_token` on `Subscribe` are Meta's per-WABA callback
override, for Tech Providers routing several WABAs' notifications to different webhook
URLs instead of the one callback URL configured on the app itself.

### Verified examples

```ruby
Whatsapp::SubscribedApp::Subscribe.call
# => #<Response::Subscription success=true data=[#<Response::App id="123..." name="My App" ...>]>

Whatsapp::SubscribedApp::List.call(fields: %w[id name])
# => #<Response::Collection data=[#<Response::App id="123..." name="My App" link=nil ...>]>

Whatsapp::SubscribedApp::Unsubscribe.call
# => #<Response::Unsubscription success=true>
```

## Not implemented

- Pagination on `List` — not documented for this edge.
- Any client-side format validation on `override_callback_uri` (e.g. requiring HTTPS).
  Meta enforces this server-side; mirroring `MessageTemplates`, this gem checks only
  what's documented as a client-side rule, not speculative hardening.

## Adding a new field (checklist)

- [ ] Confirm Meta actually publishes it for this edge.
- [ ] Write the failing spec under `spec/ruby/whatsapp/subscribed_app/...`
- [ ] Add the attribute to the relevant `Response::*` class, with a `# @!attribute` tag
- [ ] Thread any new request parameter through the owning action class's `.call`
- [ ] Add a row/example to this file
- [ ] `bundle exec rake` green before committing
