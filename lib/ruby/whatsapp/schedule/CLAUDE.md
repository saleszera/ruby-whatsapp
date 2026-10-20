# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory wraps the `schedules` edge of a WhatsApp Business Account: campaign
schedules, each one an approved template (`hsm_id`) sent to an audience (`audience_id`)
at a Unix `delivery_time`. It *sends* templates that already exist; creating and
managing the templates themselves is `../message_templates/`.

Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api

## Why `List` and `Create` are shaped differently

One class per action, like `../subscribed_app/`: listing and creating share no identity
or validation rules that would justify one class with two methods.

- `List` is a stateless class-level `.call`, like `SubscribedApp::List` and
  `BusinessPhoneNumber::Account::Get`. A read has nothing worth checking locally.
- `Create` is a validated instance with a public `#serialize` plus `.call`, like
  `BusinessPhoneNumber::RequestCode` and `Account::Update`. Meta documents all six body
  fields as required, so a missing one fails before the request instead of costing one.

## Architecture

```
Schedule                         module doc + Error (Whatsapp::Schedule::Error)
  ├── Transport                  shared: edge_path(client); guard via Whatsapp::PathBuilding
  ├── Statuses                   COMPLETED, FAILED, SCHEDULED, SENDING; for comparison only
  ├── List                       GET  -> Response::Collection; List::Fields
  ├── Create                     POST -> Response::Created
  └── Response
        ├── Node                 one schedule: id, name, description, delivery_time, status
        ├── Collection           {data: [Node], paging}, Enumerable   (List)
        └── Created              {id}                                 (Create)
```

`Transport` and `ResponseHandling` are `extend`ed, not `include`d, since both are used
from class-level `.call` methods. The `waba_id` guard and its wording come from
`Whatsapp::PathBuilding` (`../path_building.rb`).

### Paging is reused, not duplicated

`Response::Collection#paging` is a `MessageTemplates::Response::Paging`. The Graph API
cursor shape is identical and nothing in that class is template-specific, so a second
copy would be pure duplication. It keeps only `cursors.before`/`cursors.after`, not the
`previous`/`next` URLs Meta also sends; the cursors are what `List.call(after:)` takes.

## Conventions

Same as `../subscribed_app/CLAUDE.md` unless noted:

1. Every `Response::*` class follows the gem's `.deserialize(data)` convention:
   `data ||= {}` first, `Array(data["key"]).map { ... }` for lists, tolerant of a nil or
   partial payload.
2. `Node#status` stays the raw string Meta sent and is never validated on the way in,
   so a status Meta adds later still round-trips. `Statuses` and the
   `scheduled?`/`sending?`/`completed?`/`failed?` predicates are for comparison only,
   mirroring `Account::Details`.
3. Every failure raises `Whatsapp::Schedule::Error` (missing `waba_id` via
   `Transport#edge_path`, non-2xx via `ResponseHandling#handle_response!`), never the
   generic `Whatsapp::RequestError`. Local validation raises `ActiveModel::ValidationError`.
4. Kwargs keep Meta's wire names (`hsm_id`, `waba_cs_id`), as `MessageTemplates#delete`
   already does with `hsm_id`.

## Reference

| Method | Request | Returns |
|---|---|---|
| `List.call(client:, fields:, limit:, after:, before:)` | `GET /{waba_id}/schedules` | `Response::Collection` |
| `Create.call(hsm_id:, audience_id:, waba_cs_id:, name:, description:, delivery_time:, client:)` | `POST /{waba_id}/schedules` | `Response::Created` |

Both require `waba_id` (set via `Whatsapp.configure` or `Client.new(waba_id:)`).

**Meta's default `fields` omit `id`** (they are `name`, `description`, `delivery_time`,
`status`). Pass `fields: List::Fields::ALL`, or a list including `"id"`, to get it.

### Examples

```ruby
Whatsapp::Schedule::Create.call(
  hsm_id: "1234567890", audience_id: "2345678901", waba_cs_id: "3456789012",
  name: "Black Friday", description: "Black Friday promo to VIP customers",
  delivery_time: Time.now.to_i + 3600
).id
# => "9876543210"

page = Whatsapp::Schedule::List.call(fields: Whatsapp::Schedule::List::Fields::ALL, limit: 50)
page.select(&:scheduled?).map(&:name)
Whatsapp::Schedule::List.call(after: page.next_cursor) if page.next_cursor
```

These are spec-verified against stubbed responses, not a live WABA; Meta publishes no
example success payload for either endpoint.

## Unverified against the live API

1. **What `waba_cs_id` is.** Meta documents it only as "WABA customer status ID (phone
   number)", which could mean a phone number ID or the number itself. It is passed
   through as given.
2. **The live response shapes.** Both are built from Meta's schema tables, not a
   captured response.

## Not implemented

- **A client-side `limit` check.** Meta documents 1–100, but reads are cheap and Meta
  rejects an out-of-range value itself; `List` stays a plain class method.
- **A future-`delivery_time` check.** Meta does not document one.
- **`Time` coercion for `delivery_time`.** The wire type is an int64 Unix timestamp;
  pass `time.to_i`.
- **Auto-pagination** and the `paging.previous`/`paging.next` URLs. See "Paging is
  reused" above, and `MessageTemplates::Response::Collection` for why paging is exposed
  rather than followed.
- **Reading, updating, or cancelling one schedule.** Meta documents only `GET` and
  `POST` on this edge.

## Adding a new field (checklist)

- [ ] Confirm Meta actually publishes it for this edge.
- [ ] Write the failing spec under `spec/ruby/whatsapp/schedule/...`
- [ ] Add the attribute to `Response::Node` (with a `# @!attribute` tag) and, for a
      readable field, a constant to `List::Fields`
- [ ] For a request field, thread it through `Create#initialize`, `#serialize`, and `.call`
- [ ] Add a row or example to this file and to `docs/schedule/README.md`
- [ ] `bundle exec rake` green before committing
