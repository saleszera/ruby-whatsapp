# `business_capability_update`

Your account's capability limits changed — how many conversations each number may
start per day, and how many numbers the business may hold. A limit increase usually
follows sustained good quality; a decrease follows the opposite.

`Whatsapp::Webhook::BusinessCapabilityUpdate` · confidence: **moderate**

## Payload

```json
{ "field": "business_capability_update",
  "value": { "max_daily_conversation_per_phone": 100000,
             "max_phone_numbers_per_business": 20 } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `max_daily_conversation_per_phone` | Business-initiated conversations per number per day |
| `max_phone_numbers_per_business` | Numbers this business may register |

## Handling it

```ruby
when "business_capability_update"
  caps = change.value
  Throttle.update!(daily_cap: caps.max_daily_conversation_per_phone)
```

Useful for pacing an outbound campaign against the real ceiling rather than a
hard-coded guess.

> **Best-effort schema.** Meta publishes no JSON example for this field. Validate
> against a real payload before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
