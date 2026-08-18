# `account_alerts`

Operational alerts about the account — messaging-limit changes, policy notices,
capability warnings.

`Whatsapp::Webhook::AccountAlerts` · confidence: **moderate**

## Payload

```json
{ "field": "account_alerts",
  "value": {
    "entity_type": "WABA",
    "entity_id": "102290129340398",
    "alert_severity": "INFO",
    "alert_status": "ACTIVE",
    "alert_description": "Messaging limit increased"
  } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `entity_type` | What the alert is about, e.g. `WABA` |
| `entity_id` | That entity's ID |
| `alert_severity` | e.g. `INFO`, `WARNING`, `CRITICAL` |
| `alert_status` | e.g. `ACTIVE`, `RESOLVED` |
| `alert_description` | Human-readable text |

## Handling it

```ruby
when "account_alerts"
  alert = change.value
  Ops.notify(alert.alert_description) if alert.alert_severity != "INFO"
```

> **Best-effort schema.** Meta publishes no JSON example for this field. Validate
> against a real payload before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
