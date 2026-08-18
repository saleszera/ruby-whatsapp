# `account_update`

Something changed about the WhatsApp Business Account itself — most importantly, a ban
or a restriction. If you handle exactly one non-`messages` field, make it this one:
a banned WABA stops delivering everything.

`Whatsapp::Webhook::AccountUpdate` · confidence: **moderate**

## Payload

```json
{ "field": "account_update",
  "value": {
    "phone_number": "15550783881",
    "event": "DISABLED_UPDATE",
    "ban_info": { "waba_ban_state": "DISABLE", "waba_ban_date": "2024-01-01" }
  } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `phone_number` | The number the event concerns |
| `event` | e.g. `DISABLED_UPDATE`, `VERIFIED_ACCOUNT`, `ACCOUNT_RESTRICTION` |
| `ban_info` | `AccountUpdate::BanInfo` or `nil` |

### `BanInfo`

| Accessor | Meaning |
| --- | --- |
| `waba_ban_state` | e.g. `DISABLE`, `WARN`, `REINSTATE` |
| `waba_ban_date` | When it takes effect |

## Handling it

```ruby
when "account_update"
  update = change.value

  if update.ban_info
    Ops.page!(
      "WABA #{entry.id} ban state #{update.ban_info.waba_ban_state} " \
      "effective #{update.ban_info.waba_ban_date}"
    )
  end
```

> **Best-effort schema.** Meta publishes no JSON example for this field. Validate
> against a real payload before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
