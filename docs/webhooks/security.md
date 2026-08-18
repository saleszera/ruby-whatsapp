# `security`

Security events on a phone number — chiefly two-step verification being enabled or
disabled.

`Whatsapp::Webhook::Security` · confidence: **low**

## Payload

```json
{ "field": "security",
  "value": { "display_phone_number": "15550783881",
             "event": "TWO_STEP_VERIFICATION_ENABLED",
             "requester": "16505551234" } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `display_phone_number` | The number affected |
| `event` | e.g. `TWO_STEP_VERIFICATION_ENABLED` / `..._DISABLED` |
| `requester` | Who initiated the change |

## Handling it

```ruby
when "security"
  event = change.value
  AuditLog.create!(kind: event.event, subject: event.display_phone_number,
                   actor: event.requester)
```

The two-step verification PIN this concerns is the same one
[`Register`](../business_phone_number/README.md#registering) consumes.

> **Best-effort schema, low confidence.** Meta describes this field in one line and
> publishes no JSON example. Validate against a real payload before depending on it in
> production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
