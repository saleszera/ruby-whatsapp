# `smb_app_state_sync`

Contact-book and app-state changes synced from the WhatsApp Business app. Arrives
alongside [`history`](history.md) when a number moves onto Cloud API.

`Whatsapp::Webhook::SmbAppStateSync` · confidence: **low-moderate**

## Payload

```json
{ "field": "smb_app_state_sync",
  "value": { "state_sync": [{ "type": "contact",
                              "action": "add",
                              "contact": { "full_name": "Jane Doe", "phone_number": "+1" } }] } }
```

## Accessors

| Accessor | Type |
| --- | --- |
| `state_sync` | `Array<SmbAppStateSync::StateSync>` |

### `StateSync`

| Accessor | Meaning |
| --- | --- |
| `type` | e.g. `contact` |
| `action` | e.g. `add`, `update`, `remove` |
| `contact` | **Raw Hash** — the shape is undocumented |

## Handling it

```ruby
when "smb_app_state_sync"
  change.value.state_sync.each do |sync|
    next unless sync.type == "contact"

    case sync.action
    when "add", "update"
      Contact.upsert_from_meta(sync.contact)
    when "remove"
      Contact.find_by(phone: sync.contact["phone_number"])&.destroy
    end
  end
```

> **Best-effort schema, low-moderate confidence.** `contact` is left as a raw hash
> precisely because its keys are unverified. Validate against a real payload before
> depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
