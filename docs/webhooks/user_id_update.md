# `user_id_update`

A WhatsApp user's business-scoped user ID (BSUID) changed — most commonly because they
changed their phone number (see the [`system` message type's `user_changed_user_id`
event](messages.md#system) for the same event surfaced on the `messages` field).

`Whatsapp::Webhook::UserIdUpdate` · confidence: **confirmed** — Meta publishes a real
JSON example

## Payload

```json
{ "field": "user_id_update",
  "value": {
    "messaging_product": "whatsapp",
    "metadata": { "display_phone_number": "15550783881", "phone_number_id": "106540352242922" },
    "contacts": [{ "profile": { "name": "Jane Doe" }, "wa_id": "16505551234" }],
    "user_id_update": [
      {
        "wa_id": "16505551234",
        "detail": "User id for Jane Doe has been updated.",
        "user_id": { "previous": "US.OLD", "current": "US.NEW" },
        "parent_user_id": { "previous": "US.ENT.OLD", "current": "US.ENT.NEW" },
        "timestamp": "1750030073"
      }
    ]
  } }
```

`parent_user_id` is present only if you have enrolled in [parent
BSUIDs](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#parent-business-scoped-user-ids).

## Accessors

| Accessor | Meaning |
| --- | --- |
| `messaging_product` | `"whatsapp"` |
| `metadata` | `Metadata` — `display_phone_number`, `phone_number_id` |
| `contacts` | `Array<Contact>` — the [same BSUID-aware `Contact`](messages.md#business-scoped-user-ids-bsuid) used by `messages` |
| `updates` | `Array<UserIdUpdate::Entry>` |

### `Entry`

| Accessor | Meaning |
| --- | --- |
| `wa_id` | The user's phone number, if available |
| `detail` | Human-readable description of the change |
| `user_id` | `Entry::IdChange` — the user's previous and current BSUID |
| `parent_user_id` | `Entry::IdChange` or `nil` — previous and current parent BSUID |
| `timestamp` | Unix seconds, as a String |

### `IdChange`

| Accessor | Meaning |
| --- | --- |
| `previous` | The BSUID before the change |
| `current` | The BSUID after the change |

## Handling it

```ruby
when "user_id_update"
  change.value.updates.each do |update|
    User.find_by(bsuid: update.user_id.previous)&.update!(bsuid: update.user_id.current)
  end
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#user_id_update-webhooks>
