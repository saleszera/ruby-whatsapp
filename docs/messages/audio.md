# Audio Messages

Sends a voice note or audio clip.

```ruby
Whatsapp::Messages.send_audio!(to: "+15551234567", link: "https://example.com/clip.mp3")
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `id` | one of | A media ID from [`Media#upload`](../media/README.md) |
| `link` | one of | A publicly reachable HTTPS URL |

**Either `id` or `link` is required.**

> **No caption.** Unlike [image](image.md), [video](video.md), and
> [document](document.md), the Cloud API has no caption field for audio, so the class
> does not accept one. Send a separate [text message](text.md) if you need
> accompanying copy.

## Serialized payload

```ruby
Whatsapp::Messages::Audio.new(to: "+15551234567", link: "https://example.com/clip.mp3").serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "audio",
#   audio: { link: "https://example.com/clip.mp3" }
# }
```

## Validation errors

```ruby
Whatsapp::Messages.send_audio!(to: "+15551234567")
# => ActiveModel::ValidationError: Either id or link must be present
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/audio-messages>
