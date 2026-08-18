# Image Messages

Shares a photo or graphic — a product shot, a receipt, a screenshot.

```ruby
Whatsapp::Messages.send_image!(
  to: "+15551234567",
  link: "https://example.com/photo.jpg",
  caption: "Our new product"
)
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `id` | one of | A media ID from [`Media#upload`](../media/README.md) |
| `link` | one of | A publicly reachable HTTPS URL |
| `caption` | no | Max **1024** characters |

**Either `id` or `link` is required** — never both are mandatory, but at least one
must be present. Prefer `id` when you'll send the same asset more than once: Meta
caches an uploaded asset, whereas a `link` is re-fetched on every send.

```ruby
media    = Whatsapp::Media.new
media_id = media.upload(file_path: "photo.jpg", type: "image/jpeg")

Whatsapp::Messages.send_image!(to: "+15551234567", id: media_id, caption: "Our new product")
```

## Serialized payload

```ruby
Whatsapp::Messages::Image.new(
  to: "+15551234567", link: "https://example.com/photo.jpg", caption: "Our new product"
).serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "image",
#   image: { link: "https://example.com/photo.jpg", caption: "Our new product" }
# }
```

The `image` hash is compacted, so absent optional keys never reach the wire.

## Validation errors

```ruby
Whatsapp::Messages.send_image!(to: "+15551234567")
# => ActiveModel::ValidationError: Either id or link must be present

Whatsapp::Messages.send_image!(to: "+15551234567", link: "https://example.com/p.jpg", caption: "x" * 1025)
# => ActiveModel::ValidationError: Caption is too long (maximum is 1024 characters)
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/image-messages>
