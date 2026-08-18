# `phone_number_quality_update`

A phone number's quality rating or messaging tier changed. A downgrade cuts how many
conversations that number may start per day, so this is worth alerting on.

`Whatsapp::Webhook::PhoneNumberQualityUpdate` · confidence: **moderate**

## Payload

```json
{ "field": "phone_number_quality_update",
  "value": { "display_phone_number": "15550783881",
             "event": "DOWNGRADE",
             "current_limit": "TIER_50" } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `display_phone_number` | The number affected |
| `event` | e.g. `UPGRADE`, `DOWNGRADE`, `FLAGGED`, `UNFLAGGED` |
| `current_limit` | e.g. `TIER_50`, `TIER_250`, `TIER_1K`, `TIER_UNLIMITED` |

## Handling it

```ruby
when "phone_number_quality_update"
  quality = change.value

  Ops.alert("#{quality.display_phone_number} downgraded to #{quality.current_limit}") \
    if quality.event == "DOWNGRADE"
```

> **Best-effort schema.** Meta publishes no JSON example for this field. Validate
> against a real payload before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
