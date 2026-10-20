# `smb_app_state_sync`

Contact-book and app-state changes synced from the WhatsApp Business app. Arrives
alongside [`history`](history.md) when a number moves onto Cloud API.

`Whatsapp::Webhook::SmbAppStateSync` · confidence: **high**

## Payload

```json
{ "field": "smb_app_state_sync",
  "value": {
    "messaging_product": "whatsapp",
    "metadata": { "display_phone_number": "15550783881", "phone_number_id": "106540352242922" },
    "state_sync": [
      { "type": "contact",
        "contact": { "full_name": "Pablo Morales",
                     "first_name": "Pablo",
                     "phone_number": "16505551234",
                     "user_id": "US.13491208655302741918",
                     "username": "pablomorales" },
        "action": "add",
        "metadata": { "timestamp": "1750030073" } }
    ] } }
```

## Accessors

| Accessor | Type |
| --- | --- |
| `messaging_product` | `"whatsapp"` |
| `metadata` | `Metadata` — the business phone number whose address book this is |
| `state_sync` | `Array<SmbAppStateSync::StateSync>` |
| `raw` | The untouched `value` hash |

### `StateSync`

| Accessor | Meaning |
| --- | --- |
| `type` | `"contact"` is the only documented kind |
| `action` | e.g. `add`, `update`, `remove` |
| `contact` | An `SmbAppStateSync::Contact`, or `nil` |
| `timestamp` | Flattened up from the entry's own `metadata.timestamp` |

The entry's `metadata` is **not** the value-level `Metadata` — it carries only a
timestamp, so the wrapper is dropped rather than typed.

### `Contact`

| Accessor | Meaning |
| --- | --- |
| `full_name` | |
| `first_name` | |
| `phone_number` | Omitted once the contact adopts a username |
| `user_id` | Their [BSUID](messages.md#business-scoped-user-ids-bsuid) |
| `parent_user_id` | Their parent BSUID, present only if enrolled |
| `username` | Set only if adopted. Read **flat** here, unlike `Contact#username` on `messages`, which Meta nests under `profile` |

This is the gem's third `Contact`, and none are interchangeable:
[`Webhook::Contact`](messages.md#value-accessors) is a notification's sender identity,
[`Message::Contacts::Contact`](messages.md#contacts) is a shared contact *card*, and this
is a device address-book row.

## Handling it

```ruby
when "smb_app_state_sync"
  change.value.state_sync.each do |sync|
    next unless sync.type == "contact"

    case sync.action
    when "add", "update"
      Contact.upsert_from_meta(bsuid: sync.contact.user_id, phone: sync.contact.phone_number,
                               name: sync.contact.full_name, username: sync.contact.username)
    when "remove"
      Contact.find_by(bsuid: sync.contact.user_id)&.destroy
    end
  end
```

> **Changed in 0.6.0.** `StateSync#contact` used to be a raw Hash, because Meta had
> published no shape for it. It is now a typed `Contact`, so `sync.contact["phone_number"]`
> becomes `sync.contact.phone_number`, and an entry carrying no contact returns `nil`
> rather than `{}`.

> The `state_sync` key itself is still inferred from the field name rather than confirmed
> by a published example — hence `raw`, so a drifted key leaves a trace.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
