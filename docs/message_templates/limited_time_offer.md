# Limited-Time Offer Templates

Adds a live countdown and a copyable coupon code to a marketing message. The countdown
is rendered by WhatsApp itself, so the urgency stays accurate no matter when the
recipient opens the thread.

> **MARKETING only**, and the presence of a `LIMITED_TIME_OFFER` component tightens
> four other rules at once. See [The knock-on rules](#the-knock-on-rules).

```ruby
Whatsapp::MessageTemplates.new.create(
  name: "spring_offer", language: "en_US", category: "MARKETING",
  components: [
    { type: :header, format: "IMAGE", header_handle: "4::aW..." },
    { type: :limited_time_offer, text: "Expiring offer!", has_expiration: true },
    { type: :body, text: "Good news, {{1}}! Use code {{2}} for 25% off.",
      example: ["Pablo", "SPRING25"] },
    { type: :buttons, buttons: [
      { type: :copy_code, example: "SPRING25" },
      { type: :url, text: "Book now!", url: "https://example.com/o?c={{1}}", example: "n3mtql" },
    ] },
  ]
)
```

## The component

| Field | Required | Rules |
| --- | --- | --- |
| `text` | yes | Max **16** characters — the offer label |
| `has_expiration` | no | `true` shows the countdown |

It serializes nested, unlike every other component:

```ruby
{ type: "LIMITED_TIME_OFFER", limited_time_offer: { text: "Expiring offer!", has_expiration: true } }
```

## The knock-on rules

Adding a limited-time offer changes what the rest of the template may contain. These
are enforced by `ComponentSet`, which is the only object that can see all the
components at once:

| Rule | Error if violated |
| --- | --- |
| **No `FOOTER`** at all | `a FOOTER is not allowed in a LIMITED_TIME_OFFER template` |
| `BODY` drops to **600** chars (from 1024) | `the BODY of a LIMITED_TIME_OFFER template is limited to 600 characters` |
| Header must be **`IMAGE` or `VIDEO`** | `the header must be IMAGE or VIDEO in a LIMITED_TIME_OFFER template, got TEXT` |
| Copy-code button must be **first** | `the copy-code button must be first in a LIMITED_TIME_OFFER template` |
| Copy-code `example` ≤ **15** chars (from 20) | `the copy-code example is limited to 15 characters in a LIMITED_TIME_OFFER template` |

## Serialized payload

```ruby
Whatsapp::MessageTemplates::Template.new(
  name: "limited_time_offer_caribbean_pkg_2023", language: "en_US", category: "marketing",
  components: [
    { type: :header, format: "image", header_handle: "4::aW" },
    { type: :limited_time_offer, text: "Expiring offer!", has_expiration: true },
    { type: :body, text: "Good news, {{1}}! Use code {{2}} to get 25% off!",
      example: ["Pablo", "CARIBE25"] },
    { type: :buttons, buttons: [
      { type: :copy_code, example: "CARIBE25" },
      { type: :url, text: "Book now!", url: "https://x.test/offers?code={{1}}", example: "n3mtql" },
    ] },
  ]
).serialize
# => {
#   name: "limited_time_offer_caribbean_pkg_2023", language: "en_US", category: "MARKETING",
#   parameter_format: "POSITIONAL",
#   components: [
#     { type: "HEADER", format: "IMAGE", example: { header_handle: ["4::aW"] } },
#     { type: "LIMITED_TIME_OFFER",
#       limited_time_offer: { text: "Expiring offer!", has_expiration: true } },
#     { type: "BODY", text: "Good news, {{1}}! Use code {{2}} to get 25% off!",
#       example: { body_text: [["Pablo", "CARIBE25"]] } },
#     { type: "BUTTONS", buttons: [
#       { type: "COPY_CODE", example: "CARIBE25" },
#       { type: "URL", text: "Book now!", url: "https://x.test/offers?code={{1}}",
#         example: ["n3mtql"] }] },
#   ]
# }
```

## Media handles

`header_handle` comes from Meta's Resumable Upload API, not
[`Media#upload`](../media/README.md) — see
[README.md § Not wrapped](README.md#not-wrapped).

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/marketing-templates/limited-time-offer-templates>
