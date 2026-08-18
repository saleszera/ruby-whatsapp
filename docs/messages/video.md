# Video Messages

Shares a video — an instructional clip, a product demo, an unboxing.

```ruby
Whatsapp::Messages.send_video!(to: "+15551234567", id: "1234567890", caption: "Demo video")
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `id` | one of | A media ID from [`Media#upload`](../media/README.md) |
| `link` | one of | A publicly reachable HTTPS URL |
| `caption` | no | Max **1024** characters |

**Either `id` or `link` is required.** Videos are the kind where uploading once and
reusing the `id` pays off most — a `link` makes Meta re-download the whole file on
every single send.

## Serialized payload

```ruby
Whatsapp::Messages::Video.new(to: "+15551234567", id: "1234567890", caption: "Demo video").serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "video",
#   video: { id: "1234567890", caption: "Demo video" }
# }
```

## Validation errors

```ruby
Whatsapp::Messages.send_video!(to: "+15551234567")
# => ActiveModel::ValidationError: Either id or link must be present
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/video-messages>
