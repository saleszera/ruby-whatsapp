# `user_preferences`

A customer changed their marketing preferences — most importantly, opting **out**.
Respecting this is not optional: continuing to send marketing to someone who stopped
you damages your quality rating and breaches Meta's policy.

`Whatsapp::Webhook::UserPreferences` · confidence: **confirmed**

## Payload

```json
{ "field": "user_preferences",
  "value": {
    "messaging_product": "whatsapp",
    "metadata": { "display_phone_number": "15550783881", "phone_number_id": "106540352242922" },
    "contacts": [
      { "profile": { "name": "Pablo M.", "username": "pablomorales" },
        "wa_id": "16505551234",
        "user_id": "US.13491208655302741918" }
    ],
    "user_preferences": [
      { "wa_id": "16505551234",
        "user_id": "US.13491208655302741918",
        "detail": "User requested to stop marketing messages",
        "category": "marketing_messages",
        "value": "stop",
        "timestamp": 1750030073 }
    ] } }
```

Note the nesting: the entries sit under a repeat of the field's own name, the same shape
[`user_id_update`](user_id_update.md) uses.

## Value accessors

| Accessor | Type |
| --- | --- |
| `messaging_product` | `String` — always `"whatsapp"` |
| `metadata` | `Metadata` — the business phone number this arrived on |
| `contacts` | `Array<Contact>` — `profile_name`, `username`, `wa_id`, `user_id`, `parent_user_id` |
| `preferences` | `Array<UserPreferences::Entry>` |
| `raw` | The untouched `value` hash |

## Entry accessors

| Accessor | Meaning |
| --- | --- |
| `wa_id` | The customer's phone number, or `nil` once they adopt a username |
| `user_id` | Their [BSUID](messages.md#business-scoped-user-ids-bsuid) — the identifier that is always there |
| `parent_user_id` | Their parent BSUID, present only if enrolled |
| `detail` | Human-readable description |
| `category` | `"marketing_messages"` is the only documented value |
| `value` | `"stop"` or `"resume"` |
| `timestamp` | Unix seconds. Meta sends a **number** here, unlike the String timestamps on `messages` |

> `Entry#value` sits inside the change's own `value` hash, so the full path reads
> `change.value.preferences.first.value`. Meta's naming, not ours.

## Handling it

An opt-out from a username adopter may carry no phone number at all, so key off the
BSUID and fall back to `wa_id` — not the other way round:

```ruby
when "user_preferences"
  change.value.preferences.each do |preference|
    customer =
      Customer.find_by(bsuid: preference.user_id) ||
      Customer.find_by(wa_id: preference.wa_id)

    customer&.update!(
      marketing_opt_in: preference.value != "stop",
      marketing_opt_in_changed_at: Time.at(preference.timestamp.to_i)
    )
  end
```

Gate every `MARKETING`-category [template send](../messages/template.md) on this flag.
`UTILITY` and `AUTHENTICATION` templates are unaffected.

> **Changed in 0.6.0.** This field used to expose `wa_id`/`detail`/`value`/`timestamp`
> directly on `change.value`. Meta nests them one level deeper than the gem assumed, so
> those accessors could never return anything but `nil`; they are now on `Entry`.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
