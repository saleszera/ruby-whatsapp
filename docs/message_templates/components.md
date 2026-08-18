# Components and Buttons Reference

The complete registry of what a template can be built from. A component validates
itself; `ComponentSet` validates how components relate to each other.

## Component types

Resolved through the frozen `Component::TYPES` registry — never `const_get` on caller
input.

| `type:` | Wire type | Purpose |
| --- | --- | --- |
| `:header` | `HEADER` | Text, media, or location above the body |
| `:body` | `BODY` | **Required, exactly one** |
| `:footer` | `FOOTER` | Small print below the body |
| `:buttons` | `BUTTONS` | One component holding 1–10 buttons |
| `:carousel` | `CAROUSEL` | [2–10 identical cards](carousel.md) |
| `:limited_time_offer` | `LIMITED_TIME_OFFER` | [Countdown + coupon](limited_time_offer.md) |

An unknown type raises before any request:

```ruby
# => Whatsapp::MessageTemplates::TemplateError: Unknown component type: :greeting.
#    Known types: header, body, footer, buttons, carousel, limited_time_offer
```

### Header

| `format` | Fields | Rules |
| --- | --- | --- |
| `TEXT` | `text`, `example` | ≤ **60** chars, **at most one** placeholder, no Markdown, no `header_handle` |
| `IMAGE` `VIDEO` `DOCUMENT` `GIF` | `header_handle` | No `text` |
| `LOCATION` | — | Nothing else; coordinates are supplied when sending |

Max **one** header per template.

The Markdown check rejects `*` `_` `~` `` ` `` in the literal text but **ignores
placeholder contents** — named placeholders are lowercase-and-underscores by
definition, so scanning raw text would reject `{{sale_start_date}}` for its underscore
and make named parameters unusable in a text header.

```ruby
{ type: :header, format: "TEXT", text: "Order {{1}} confirmed", example: ["#1234"] }
{ type: :header, format: "IMAGE", header_handle: "4::aW..." }
{ type: :header, format: "LOCATION" }
```

A `LOCATION` header requires the category to be `UTILITY` or `MARKETING`.

### Body

**Required, exactly one per template.** Two mutually exclusive shapes:

| Shape | Fields | Rules |
| --- | --- | --- |
| Text | `text`, `example` | ≤ **1024** chars, any number of placeholders, example count must match |
| Authentication | `add_security_recommendation` | See [authentication.md](authentication.md) |

```ruby
{ type: :body, text: "Thank you, {{1}}!", example: ["Pablo"] }
{ type: :body, add_security_recommendation: true }
```

Example count is checked against the **unique** placeholder count, so a repeated
`{{1}}` needs one example, not two.

### Footer

Max **one**. Two mutually exclusive shapes:

| Shape | Fields | Rules |
| --- | --- | --- |
| Text | `text` | ≤ **60** chars, **no placeholders at all** |
| Authentication | `code_expiration_minutes` | Integer in **1..90** |

```ruby
{ type: :footer, text: "Thanks for shopping with us" }
{ type: :footer, code_expiration_minutes: 15 }
```

Forbidden entirely alongside a [limited-time offer](limited_time_offer.md).

### Buttons

Max **one** `BUTTONS` component, holding **1–10** buttons.

| Button type | Cap per template |
| --- | --- |
| `QUICK_REPLY` | 10 |
| `URL` | 2 |
| `PHONE_NUMBER` | 1 |
| `COPY_CODE` | 1 |
| `OTP` | uncapped — Meta publishes no limit |

> **Quick replies must be contiguous.** They may sit at the start or the end, but not
> with another type between them. `[QR, QR, URL]` and `[URL, QR, QR]` are fine;
> `[QR, URL, QR]` raises `quick reply buttons must be grouped together, without other
> types between them`.

## Button types

Resolved through the frozen `Button::TYPES` registry.

| `type:` | Wire type | Fields |
| --- | --- | --- |
| `:quick_reply` | `QUICK_REPLY` | `text` ≤ **25** |
| `:url` | `URL` | `text` ≤ 25, `url` ≤ **2000**, `example` |
| `:phone_number` | `PHONE_NUMBER` | `text` ≤ 25, `phone_number` ≤ **20** |
| `:copy_code` | `COPY_CODE` | `example` ≤ **20** (a bare String), **no `text`** |
| `:otp` | `OTP` | `otp_type`, `supported_apps`, `zero_tap_terms_accepted` |

```ruby
{ type: :quick_reply,  text: "More like this" }
{ type: :url,          text: "Track order", url: "https://example.com/o/{{1}}", example: "1234" }
{ type: :phone_number, text: "Call", phone_number: "15550051310" }
{ type: :copy_code,    example: "SPRING25" }
{ type: :otp,          otp_type: "COPY_CODE" }
```

### The URL button's single trailing variable

A URL button may contain **at most one variable, and it must be at the end**:

```ruby
{ type: :url, text: "Track", url: "https://example.com/{{1}}/details" }
# => ActiveModel::ValidationError: Url variable must be at the end of the URL
```

> The URL variable is counted by **occurrence**, not by unique name, so
> `.../{{1}}/details/{{1}}` is rejected: it ends in a placeholder and names one
> parameter, but the leading one still sits mid-URL. Everywhere else — body examples
> above all — the unique count is the correct one, since Meta treats a repeated
> `{{1}}` as a single parameter needing a single example.

Its `example` is a **flat array on the button**, unlike header and body examples,
which are nested under an `example` key. A bare String is wrapped for you.

### Buttons Meta supplies the label for

`COPY_CODE` and `OTP` reject `text` (and `autofill_text`) — Meta writes and localises
those labels:

```ruby
{ type: :copy_code, example: "SPRING25", text: "Copy" }
# => ActiveModel::ValidationError: Text cannot be set on a copy-code button;
#    Meta supplies the label
```

## Cross-component rules

Owned by `ComponentSet`, because it is the only object that can see the siblings:

- **Exactly one** `BODY`.
- **At most one** each of `HEADER`, `FOOTER`, `BUTTONS`, `CAROUSEL`,
  `LIMITED_TIME_OFFER`.
- `CAROUSEL` or `LIMITED_TIME_OFFER` → category must be `MARKETING`.
- A `LOCATION` header → category must be `UTILITY` or `MARKETING`.
- `LIMITED_TIME_OFFER` present → `FOOTER` forbidden, `BODY` ≤ **600**, header
  `IMAGE`/`VIDEO` only, copy-code `example` ≤ **15** and that button must be **first**.

The category-dependent rules are **skipped when `category` is nil** — which is exactly
what `#update` needs, since editing replaces components without re-supplying a
category.

## Not registered

Only types with a published Meta field reference get a class. Named in Meta's Graph
enum but deliberately absent:

- **Components:** `GREETING`, `ALBUM`, `CALL_PERMISSION_REQUEST`,
  `TAP_TARGET_CONFIGURATION`, `ATTACHMENT`.
- **Buttons:** `FLOW`, `MPM`, `CATALOG`, `VOICE_CALL`, `VIDEO_CALL`, `POSTBACK`,
  `BOOKING_STATUS`, `PAYMENT_REQUEST`, `REQUEST_CONTACT_INFO`. Most of these *are*
  accepted by [`LibraryTemplate`](library.md), because Meta documents them by name in
  that context.

---

**Meta docs:** <https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/>
