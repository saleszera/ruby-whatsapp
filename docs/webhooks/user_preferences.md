# `user_preferences`

A customer changed their marketing preferences — most importantly, opting **out**.
Respecting this is not optional: continuing to send marketing to someone who stopped
you damages your quality rating and breaches Meta's policy.

`Whatsapp::Webhook::UserPreferences` · confidence: **moderate**

## Payload

```json
{ "field": "user_preferences",
  "value": { "wa_id": "16505551234",
             "detail": "stopped marketing messages",
             "value": "stop",
             "timestamp": "1750263773" } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `wa_id` | The customer's WhatsApp ID |
| `detail` | Human-readable description |
| `value` | `"stop"` or `"resume"` |
| `timestamp` | Unix seconds, as a String |

## Handling it

```ruby
when "user_preferences"
  pref = change.value

  Customer
    .find_by(wa_id: pref.wa_id)
    &.update!(marketing_opt_in: pref.value != "stop",
              marketing_opt_in_changed_at: Time.at(pref.timestamp.to_i))
```

Gate every `MARKETING`-category [template send](../messages/template.md) on this flag.
`UTILITY` and `AUTHENTICATION` templates are unaffected.

> **Best-effort schema.** Meta publishes no JSON example for this field. Validate
> against a real payload before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
