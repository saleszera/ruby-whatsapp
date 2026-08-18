# `phone_number_name_update`

The verdict on a display-name change you requested for a phone number. The display
name is what customers see as the sender, and Meta reviews every change.

`Whatsapp::Webhook::PhoneNumberNameUpdate` · confidence: **moderate-high**

## Payload

```json
{ "field": "phone_number_name_update",
  "value": { "phone_number": "15550783881",
             "decision": "REJECTED",
             "requested_verified_name": "Acme Corp",
             "rejection_reason": "INCLUDES_UNSUPPORTED_CHARACTERS" } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `phone_number` | The number affected |
| `decision` | `APPROVED` or `REJECTED` |
| `requested_verified_name` | The name you asked for |
| `rejection_reason` | Why it was refused, when it was |

## Handling it

```ruby
when "phone_number_name_update"
  update = change.value

  if update.decision == "REJECTED"
    Ops.notify("Display name #{update.requested_verified_name.inspect} rejected: " \
               "#{update.rejection_reason}")
  end
```

> **Best-effort schema.** Meta publishes no JSON example for this field. Validate
> against a real payload before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
