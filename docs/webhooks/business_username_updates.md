# `business_username_updates`

A business phone number's username status changed — approved, reserved, or deleted.
Subscribe to this field to stay in sync whenever a username you claimed moves through
review, or is removed via the WhatsApp Business app.

`Whatsapp::Webhook::BusinessUsernameUpdates` · confidence: **confirmed** — Meta
publishes a real JSON example

## Payload

```json
{ "field": "business_username_updates",
  "value": {
    "display_phone_number": "15550783881",
    "username": "jaspersmarket",
    "status": "approved"
  } }
```

`username` is omitted when `status` is `"deleted"`.

## Accessors

| Accessor | Meaning |
| --- | --- |
| `display_phone_number` | The business phone number's display number |
| `username` | The username the status concerns; `nil` when `status` is `"deleted"` |
| `status` | `"approved"`, `"reserved"`, or `"deleted"` |

## Handling it

```ruby
when "business_username_updates"
  update = change.value
  PhoneNumber.find_by(display_phone_number: update.display_phone_number)
             &.update!(username: update.username, username_status: update.status)
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#business_username_updates-webhook>
