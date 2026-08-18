# Media

Upload, locate, download, and delete media assets on the Cloud API. An uploaded asset
gets a **media ID** you can pass to [image](../messages/image.md),
[video](../messages/video.md), [audio](../messages/audio.md),
[document](../messages/document.md), and [sticker](../messages/sticker.md) messages
instead of a public URL.

Addresses your **phone number** (`phone_id`), like
[messages](../messages/README.md).

```ruby
media = Whatsapp::Media.new    # or .new(client: my_client)

media_id = media.upload(file_path: "photo.jpg", type: "image/jpeg")
info     = media.get_url(media_id: media_id)
media.download(url: info["url"], save_to: "photo.jpg")
media.delete(media_id: media_id)
```

| Method | Request | Returns |
| --- | --- | --- |
| `upload(file_path:, type:)` | `POST /{phone_id}/media` (multipart) | `String` media ID |
| `get_url(media_id:)` | `GET /{media_id}?phone_number_id=` | `Hash` |
| `download(url:, save_to:)` | `GET <url>` with the bearer token | `String` — the path written |
| `delete(media_id:)` | `DELETE /{media_id}?phone_number_id=` | `Boolean` |

## Uploading

```ruby
media_id = Whatsapp::Media.new.upload(file_path: "photo.jpg", type: "image/jpeg")
# => "1234567890123456"
```

The file must exist — checked **before** the request, so a typo costs nothing:

```ruby
Whatsapp::Media.new.upload(file_path: "nope.jpg", type: "image/jpeg")
# => Whatsapp::Media::MediaError: File not found: nope.jpg
```

### Why prefer an ID over a link

Sending by `link:` makes Meta re-download the file on **every send**. Uploading once
and reusing the ID is faster, cheaper, and avoids your CDN being hammered:

```ruby
media_id = media.upload(file_path: "catalogue.pdf", type: "application/pdf")

recipients.each do |to|
  Whatsapp::Messages.send_document!(to: to, id: media_id, filename: "catalogue.pdf")
end
```

> **Not for template headers.** A media header on a *template* takes a
> `header_handle` from Meta's Resumable Upload API, which this gem does not wrap.
> These media IDs are for **sending**, not template creation — see
> [../message_templates/README.md](../message_templates/README.md#not-wrapped).

## Getting a download URL

```ruby
info = Whatsapp::Media.new.get_url(media_id: "1234567890123456")
# => { "url" => "https://lookaside.fbsbx.com/whatsapp_business/attachments/?mid=...",
#      "mime_type" => "image/jpeg", "sha256" => "...", "file_size" => 12345,
#      "id" => "1234567890123456" }
```

The URL is short-lived and requires the bearer token — you cannot hand it to a browser.
Fetch it with `#download`.

This is the step after receiving an inbound media message:

```ruby
message.media_id      # from a webhook Message::Image / Video / Audio / Document / Sticker
info = media.get_url(media_id: message.media_id)
```

## Downloading

```ruby
Whatsapp::Media.new.download(url: info["url"], save_to: "photo.jpg")
# => "photo.jpg"
```

The response body is streamed to disk chunk by chunk rather than buffered, so a large
video doesn't have to fit in memory.

### The token never leaves the allowlist

`#download` attaches your API token to the request, which makes the destination URL
security-relevant. Two guards run before anything is sent:

1. **HTTPS only.** A plain-HTTP URL is refused outright.
2. **Allowlisted hosts only.** The host must be on
   `Configuration#media_host_allowlist`, which defaults to
   `lookaside.fbsbx.com`, `mmg.whatsapp.net`, and `graph.facebook.com`.

```ruby
media.download(url: "http://lookaside.fbsbx.com/x", save_to: "f")
# => Whatsapp::Media::MediaError: Refusing to download from non-HTTPS URL: http://...

media.download(url: "https://evil.example.com/x", save_to: "f")
# => Whatsapp::Media::MediaError: Refusing to send credentials to non-allowlisted host:
#    evil.example.com
```

Matching is exact host or a dotted subdomain, so `evil-fbsbx.com` and
`fbsbx.com.attacker.com` are both rejected — a substring check would have let both
through.

Override the list if Meta serves you from a different host:

```ruby
Whatsapp.configure do |config|
  config.media_host_allowlist = %w[lookaside.fbsbx.com mmg.whatsapp.net my-proxy.internal]
end
```

## Deleting

```ruby
Whatsapp::Media.new.delete(media_id: "1234567890123456")   # => true
```

Returns a strict boolean from Meta's `{"success": true}`. A non-2xx response raises
instead of returning `false`, so `false` genuinely means Meta declined.

## Errors

Every failure raises `Whatsapp::Media::MediaError`:

| Message | Cause |
| --- | --- |
| `File not found: <path>` | `upload` — checked locally before any request |
| `Invalid media URL: <detail>` | `download` — the URL didn't parse |
| `Refusing to download from non-HTTPS URL: <url>` | `download` — HTTP scheme |
| `Refusing to send credentials to non-allowlisted host: <host>` | `download` — host not on the allowlist |
| `Failed to upload media: 400 ...` | Non-2xx from the API |
| `Failed to get media URL: ...` / `Failed to download media: ...` / `Failed to delete media: ...` | Non-2xx from the API |

Error bodies are truncated at 500 characters. See [../errors.md](../errors.md).

## Round trip: receive, download, reply

```ruby
media = Whatsapp::Media.new

change.value.messages.each do |message|
  next unless message.respond_to?(:media_id)

  info = media.get_url(media_id: message.media_id)
  path = media.download(url: info["url"], save_to: Rails.root.join("tmp", message.id))

  Whatsapp::Messages.send_text!(to: message.from, body: "Got your #{message.mime_type}, thanks!")
end
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/media>
