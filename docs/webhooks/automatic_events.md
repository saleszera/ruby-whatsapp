# `automatic_events`

Conversion and engagement events Meta attributes to a message — a purchase, a signup —
used for ad measurement.

`Whatsapp::Webhook::AutomaticEvents` · confidence: **low**

## Payload

```json
{ "field": "automatic_events",
  "value": { "event_type": "purchase",
             "message_id": "wamid.HBg...",
             "event_data": { "value": 19.99, "currency": "USD" } } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `event_type` | e.g. `purchase` |
| `message_id` | The WAMID the event is attributed to |
| `event_data` | **Raw Hash**, defaults to `{}` |

`event_data` is deliberately left as a raw hash: its keys vary by `event_type` and Meta
publishes no schema, so typing it would be guesswork.

## Handling it

```ruby
when "automatic_events"
  event = change.value

  Conversion.create!(
    kind: event.event_type,
    wamid: event.message_id,
    amount: event.event_data["value"],
    currency: event.event_data["currency"]
  )
```

> **Best-effort schema, low confidence.** Validate against a real payload before
> depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
