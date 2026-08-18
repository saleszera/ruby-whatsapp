# Template Messages

The **only** way to message a user outside the 24-hour customer-service window.
Marketing, utility, and authentication templates must be created and approved by Meta
before they can be sent.

> **Two different APIs.** This page covers *sending* an already-approved template
> (`POST /{PHONE_ID}/messages`). Creating, editing, and deleting the templates
> themselves is a separate API addressing `waba_id` — see
> [../message_templates/](../message_templates/README.md). The component schemas are
> **not** interchangeable: management uses `text` + `example` with uppercase
> `HEADER`/`BODY`/`FOOTER`, sending uses `parameters` with lowercase singular types.

```ruby
Whatsapp::Messages.send_template!(
  to: "+15551234567",
  name: "order_confirmation",
  language: { code: "en_US" }
)
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `name` | yes | The approved template's name |
| `language` | yes | `{ code: "en_US" }` — validated against the supported list |
| `components` | no | Array of components supplying placeholder values. Defaults to `[]` |

`language.code` is checked against `Whatsapp::Utils::LanguageCodes` (71 codes), so a
typo raises locally instead of coming back as a Meta error:

```ruby
Whatsapp::Utils::LanguageCodes.valid?("en_US")  # => true
Whatsapp::Utils::LanguageCodes.all.size         # => 71
```

## Components

A component supplies the *values* for the placeholders the template defines. It has a
`type`, and for buttons a `sub_type` and `index`.

| `type` | Purpose |
| --- | --- |
| `"header"` | Values for the header's placeholder |
| `"body"` | Values for the body's placeholders |
| `"button"` | Values for a dynamic button — also needs `sub_type` and `index` |

Each component holds `parameters`, and each parameter has a `type` selecting exactly
one value key:

| Parameter `type` | Value key | Shape |
| --- | --- | --- |
| `"text"` | `text` | String |
| `"currency"` | `currency` | `{ fallback_value:, code:, amount_1000: }` |
| `"date_time"` | `date_time` | `{ fallback_value: }` |
| `"image"` | `image` | `{ link: }` or `{ id: }` |
| `"document"` | `document` | `{ link: }` or `{ id: }` |
| `"video"` | `video` | `{ link: }` or `{ id: }` |
| `"location"` | `location` | `{ latitude:, longitude:, name:, address: }` |
| `"payload"` | `payload` | String — a quick-reply button's payload |

> Only `type` is validated. There is no cross-field check that the matching value key
> is populated, so `{ type: "text" }` with no `text` serializes to a bare
> `{ type: "text" }` and is rejected by Meta rather than locally.

## Examples

**Body placeholders:**

```ruby
Whatsapp::Messages.send_template!(
  to: "+15551234567",
  name: "order_confirmation",
  language: { code: "en_US" },
  components: [
    { type: "body", parameters: [{ type: "text", text: "Jane" },
                                 { type: "text", text: "860198-230332" }] },
  ]
)
```

**Media header plus body:**

```ruby
Whatsapp::Messages.send_template!(
  to: "+15551234567",
  name: "shipping_update",
  language: { code: "en_US" },
  components: [
    { type: "header", parameters: [{ type: "image", image: { link: "https://example.com/box.jpg" } }] },
    { type: "body",   parameters: [{ type: "text", text: "Jane" }] },
  ]
)
```

**A dynamic URL button** — `sub_type` and `index` identify which button in the
template's button row is being filled:

```ruby
Whatsapp::Messages.send_template!(
  to: "+15551234567",
  name: "order_confirmation",
  language: { code: "en_US" },
  components: [
    { type: "body",   parameters: [{ type: "text", text: "Jane" }] },
    { type: "button", sub_type: "url", index: 0,
      parameters: [{ type: "text", text: "1234" }] },
  ]
)
```

**A currency and a date:**

```ruby
components: [
  { type: "body", parameters: [
    { type: "currency", currency: { fallback_value: "$100.99", code: "USD", amount_1000: 100_990 } },
    { type: "date_time", date_time: { fallback_value: "February 25, 1977" } },
  ] },
]
```

## Serialized payload

```ruby
Whatsapp::Messages::Template.new(
  to: "+15551234567",
  name: "order_confirmation",
  language: { code: "en_US" },
  components: [
    { type: "body", parameters: [{ type: "text", text: "Jane" }, { type: "text", text: "#1234" }] },
  ]
).serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "template",
#   template: {
#     name: "order_confirmation",
#     language: { code: "en_US" },
#     components: [{ type: "body", parameters: [{ type: "text", text: "Jane" },
#                                               { type: "text", text: "#1234" }] }]
#   }
# }
```

With no components, the `components` key is dropped entirely rather than sent empty.

## Validation errors

```ruby
Whatsapp::Messages.send_template!(to: "+15551234567", name: "x", language: { code: "klingon" })
# => ActiveModel::ValidationError: Code is not a valid WhatsApp language code.
#    Supported codes: af, sq, ar, az, bn, bg, ca, zh_CN, ...

Whatsapp::Messages.send_template!(to: "+15551234567", name: "", language: { code: "en_US" })
# => ActiveModel::ValidationError: Name can't be blank
```

`name` is checked for presence only — an unapproved or misspelled template name comes
back from Meta, not from the validator.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/template-messages>
· [supported languages](https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/supported-languages)
