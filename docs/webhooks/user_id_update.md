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
| `user_id` | `UserIdUpdate::IdChange` or `nil` — the user's previous and current BSUID |
| `parent_user_id` | `UserIdUpdate::IdChange` or `nil` — previous and current parent BSUID |
| `timestamp` | Unix seconds, as a String |

### `IdChange`

`Whatsapp::Webhook::UserIdUpdate::IdChange` — a sibling of `Entry`, not nested inside it.
One class serves both `user_id` and `parent_user_id`, since they are the same shape, and
each is `nil` rather than an all-nil object when its key is absent.

| Accessor | Meaning |
| --- | --- |
| `previous` | The BSUID before the change |
| `current` | The BSUID after the change |

## Handling it

```ruby
when "user_id_update"
  change.value.updates.each do |update|
    next unless update.user_id  # nil when the entry carries only a parent BSUID change

    user = User.find_by(bsuid: update.user_id.previous)
    next Rails.logger.warn("[whatsapp] unknown BSUID #{update.user_id.previous}") unless user

    user.update!(bsuid: update.user_id.current)
  end
```

Report a miss rather than letting `&.update!` swallow it — a rotation you never applied
leaves you writing to a dead BSUID with no diagnostics. Log or alert; do not `raise`, or
Meta will retry a request that can never succeed. `change.value.raw` carries the untouched
payload if you need to see what actually arrived.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#user_id_update-webhooks>
