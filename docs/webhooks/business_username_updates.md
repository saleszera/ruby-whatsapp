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
  digits = update.display_phone_number.to_s.gsub(/\D/, "")
  number = PhoneNumber.find_by(display_phone_number_digits: digits)

  if number
    number.update!(username: update.username, username_status: update.status)
  else
    Rails.logger.error("[whatsapp] no PhoneNumber matching #{update.display_phone_number.inspect}")
  end
```

This field carries no `phone_number_id`, so `display_phone_number` is the only join key
you get — and Meta formats it for display, inconsistently (`"15550783881"` in one payload,
`"+1 555-078-3881"` in another). Match on digits, and report a miss instead of letting
`&.update!` swallow it: a silent no-op means you never learn the username moved. Log or
alert; do not `raise`, or a permanent formatting mismatch puts Meta into a retry loop
against a request that can never succeed. `update.raw` carries the untouched payload.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids#business_username_updates-webhook>
