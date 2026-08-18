# Managing Message Templates

[Sending a template](../messages/template.md) requires one that already exists and has
been approved by Meta. `Whatsapp::MessageTemplates` creates and manages those
templates, so they can live in your codebase and ship from CI instead of being clicked
together in WhatsApp Manager.

Addresses your **WhatsApp Business Account** (`waba_id`, not `phone_id`) and needs the
`whatsapp_business_management` permission.

```ruby
Whatsapp.configure do |config|
  config.api_key = ENV.fetch("WHATSAPP_API_KEY")
  config.waba_id = ENV.fetch("WHATSAPP_WABA_ID")
end

templates = Whatsapp::MessageTemplates.new    # or .new(client: my_client)
```

Omitting `waba_id` raises `TemplateError` before any request is made.

## The one thing to internalise

"Template" means two unrelated payload schemas depending on direction:

| | **Management** (this directory) | **Sending** ([`../messages/template.md`](../messages/template.md)) |
| --- | --- | --- |
| Endpoint | `POST /{WABA_ID}/message_templates` | `POST /{PHONE_ID}/messages` |
| ID | `client.waba_id` | `client.phone_id` |
| Permission | `whatsapp_business_management` | `whatsapp_business_messaging` |
| Defines | the template *shape*, with placeholders | the *values* for those placeholders |
| Component key | `text` + `example` | `parameters` |
| Component types | `HEADER` `BODY` `FOOTER` `BUTTONS` (uppercase) | `header` `body` `button` (lowercase) |
| Buttons | one `BUTTONS` component holding N buttons | N `button` components with `sub_type` + `index` |

The same template, both sides:

```jsonc
// MANAGEMENT: define the placeholder and give Meta a sample value for review
{ "type": "BODY",
  "text": "Thank you, {{1}}! Your order number is {{2}}.",
  "example": { "body_text": [["Pablo", "860198-230332"]] } }

// SENDING: supply real values. No text. No example.
{ "type": "body",
  "parameters": [{ "type": "text", "text": "Pablo" },
                 { "type": "text", "text": "860198-230332" }] }
```

## API

| Method | Request | Returns |
| --- | --- | --- |
| `create(**attrs)` | `POST /{waba_id}/message_templates` | [`Response::Created`](responses.md#created) |
| `create_from_library(**attrs)` | same edge, [library payload](library.md) | [`Response::Created`](responses.md#created) |
| `upsert(**attrs)` | `POST /{waba_id}/upsert_message_templates` | [`Response::Created`](responses.md#created) |
| `list(**filters)` | `GET /{waba_id}/message_templates` | [`Response::Collection`](responses.md#collection) |
| `find(template_id:, fields:)` | `GET /{template_id}` | [`Response::Node`](responses.md#node) |
| `update(template_id:, **attrs)` | `POST /{template_id}` | `Boolean` |
| `delete(name:/hsm_id:/hsm_ids:)` | `DELETE /{waba_id}/message_templates` | `Boolean` |

`update` is a **POST to the template's own ID** — `PUT`/`PATCH` are unsupported on
this edge.

## Template kinds

| Kind | Page |
| --- | --- |
| Standard utility / marketing | [standard.md](standard.md) |
| Authentication (OTP) | [authentication.md](authentication.md) |
| Marketing carousel | [carousel.md](carousel.md) |
| Limited-time offer | [limited_time_offer.md](limited_time_offer.md) |
| Library (pre-written by Meta) | [library.md](library.md) |

See [components.md](components.md) for the full component and button reference, and
[responses.md](responses.md) for what comes back.

## Template anatomy

| Field | Rules |
| --- | --- |
| `name` | `/\A[a-z0-9_]+\z/`, max **512**. Not unique — one per `(name, language)` pair |
| `language` **XOR** `languages` | Singular for `create`, the array for `upsert` |
| `category` | `AUTHENTICATION` \| `MARKETING` \| `UTILITY` |
| `parameter_format` | `POSITIONAL` (default) \| `NAMED` |
| `sub_category` | `ORDER_DETAILS` \| `ORDER_STATUS` \| `RICH_ORDER_STATUS` |
| `message_send_ttl_seconds` | Integer |
| `allow_category_change` | A no-op since 2025-04-09 |
| `cta_url_link_tracking_opted_out` | Boolean |

Enum values accept either casing and are emitted uppercase — `category: "utility"`
and `category: "UTILITY"` both work.

## Reading and paging

```ruby
page = templates.list(status: %w[APPROVED], fields: %w[name category status], limit: 25)

page.select(&:approved?).map(&:name)   # Collection is Enumerable
page.remaining                         # headroom against your account's template cap
templates.list(after: page.next_cursor) if page.next_cursor
```

Documented filters: `name`, `name_or_content`, `content`, `language`, `category`,
`status`, `quality_score`, `since`, `until`, `fields`, `limit`, `after`, `before`.
Array values are JSON-encoded (`status: %w[APPROVED PAUSED]` → `status=["APPROVED","PAUSED"]`)
**except** `fields`, which is comma-joined.

```ruby
template = templates.find(template_id: "1259544702043867")

template.status      # => "APPROVED"
template.editable?   # => true
template.components  # => raw hashes — Meta's echo, deliberately not re-validated
```

## Editing

Components are a **full replacement** — there is no partial component edit.

```ruby
templates.update(template_id: "564750795574598", category: "MARKETING")   # => true
templates.update(template_id: "564750795574598", components: [
  { type: :header, format: "TEXT", text: "Our {{1}} is on!", example: ["Spring Sale"] },
  { type: :body,   text: "Shop now through {{1}}.",          example: ["the end of April"] },
])                                                                        # => true
```

Only `APPROVED`, `REJECTED`, and `PAUSED` templates are editable (`Node#editable?`).
Editing an approved template re-submits it for review, but it keeps working meanwhile.

> **Edit rate limits.** Approved templates allow 10 edits per 30 days and 1 per 24
> hours. Neither is checkable locally — they surface as API errors.

## Deleting

Three mutually exclusive modes:

```ruby
templates.delete(name: "order_confirmation")                       # ALL language variants
templates.delete(hsm_id: "1407680676729941", name: "order_confirmation")
templates.delete(hsm_ids: %w[1387372356726668 1304694804498707])   # up to 100
```

> Deleting an approved template blocks reuse of its name for **30 days**. `DISABLED`
> templates cannot be deleted at all.

## Lifecycle

Only `APPROVED` templates can be sent. Review is asynchronous and can take 24 hours.
The outcome arrives by **webhook**, not by polling — `#find` is the fallback, not the
intended path:

| Webhook field | Page |
| --- | --- |
| `message_template_status_update` | [../webhooks/message_template_status_update.md](../webhooks/message_template_status_update.md) |
| `message_template_quality_update` | [../webhooks/message_template_quality_update.md](../webhooks/message_template_quality_update.md) |
| `message_template_components_update` | [../webhooks/message_template_components_update.md](../webhooks/message_template_components_update.md) |
| `template_category_update` | [../webhooks/template_category_update.md](../webhooks/template_category_update.md) |

Statuses: `APPROVED` `PENDING` `REJECTED` `PAUSED` `DISABLED` `IN_APPEAL`
`PENDING_DELETION` `DELETED` `LIMIT_EXCEEDED` `ARCHIVED`.

## Errors

Every failure raises `Whatsapp::MessageTemplates::TemplateError`, except local
validation failures, which raise `ActiveModel::ValidationError`.

```ruby
templates.create(name: "Order Confirmation", ...)
# => ActiveModel::ValidationError: Name must contain only lowercase alphanumeric
#    characters and underscores

templates.create(..., components: [{ type: :body, text: "Hi {{1}} and {{2}}", example: ["Pablo"] }])
# => ActiveModel::ValidationError: Example does not match the body text:
#    2 placeholders but 1 example

templates.upsert(name: "x", language: "en_US", ...)
# => Whatsapp::MessageTemplates::TemplateError: #upsert requires `languages:`
#    (an array of locale codes); use #create for a single one

templates.delete(hsm_ids: [], name: "x")
# => Whatsapp::MessageTemplates::TemplateError: hsm_ids cannot be combined with name or hsm_id
```

## Not wrapped

- **Media upload for template headers.** A media header takes a `header_handle` you
  already hold. Producing one needs Meta's **Resumable Upload API**, which this gem
  does not wrap — and it is a *different flow* from
  [`Media#upload`](../media/README.md), whose media IDs are for *sending*, not
  template creation.
- **Undocumented button types:** `FLOW`, `MPM`, `CATALOG`, `VOICE_CALL`, `VIDEO_CALL`,
  `POSTBACK`, `BOOKING_STATUS`, `PAYMENT_REQUEST`, `REQUEST_CONTACT_INFO`. Named in
  Meta's Graph enum with no published field reference.
  [`LibraryTemplate`](library.md) does accept most of them, because Meta documents them
  by name in *that* context.
- **Undocumented component types:** `GREETING`, `ALBUM`, `CALL_PERMISSION_REQUEST`,
  `TAP_TARGET_CONFIGURATION`, `ATTACHMENT`.
- The `compare` edge, `message_template_previews`, library browsing,
  archive/unarchive, auto-pagination on `#list`, and the Marketing Messages API fields
  (`bid_spec`, `optimization_spec`, `degrees_of_freedom_spec`, `product_set_id`).

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/overview>
