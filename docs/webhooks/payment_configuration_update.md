# `payment_configuration_update`

A payment provider configuration changed — the plumbing behind in-chat payments,
currently a regional feature (India, Brazil, Singapore).

`Whatsapp::Webhook::PaymentConfigurationUpdate` · confidence: **moderate**

## Payload

```json
{ "field": "payment_configuration_update",
  "value": { "configuration_name": "default",
             "provider_name": "razorpay",
             "provider_mid": "mid.1",
             "status": "ACTIVE" } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `configuration_name` | Your name for the configuration |
| `provider_name` | e.g. `razorpay`, `payu` |
| `provider_mid` | The provider's merchant ID |
| `status` | e.g. `ACTIVE`, `INACTIVE` |

## Handling it

```ruby
when "payment_configuration_update"
  config = change.value
  PaymentConfig.find_by(name: config.configuration_name)&.update!(status: config.status)
```

> **Best-effort schema.** Meta publishes no JSON example for this field. Validate
> against a real payload before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
