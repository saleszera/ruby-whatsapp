# Sticker Messages

Sends a WhatsApp sticker asset (a WebP image, animated or static).

```ruby
Whatsapp::Messages.send_sticker!(to: "+15551234567", id: "STICKER_MEDIA_ID")
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `id` | one of | A media ID from [`Media#upload`](../media/README.md) |
| `link` | one of | A publicly reachable HTTPS URL |

**Either `id` or `link` is required** — prefer `id`. Stickers are almost always
reused across many conversations, so uploading once and holding the ID avoids
re-fetching the same asset on every send.

## Serialized payload

```ruby
Whatsapp::Messages::Sticker.new(to: "+15551234567", id: "STICKER_MEDIA_ID").serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "sticker",
#   sticker: { id: "STICKER_MEDIA_ID" }
# }
```

## Validation errors

```ruby
Whatsapp::Messages.send_sticker!(to: "+15551234567")
# => ActiveModel::ValidationError: Either id or link must be present
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/sticker-messages>
