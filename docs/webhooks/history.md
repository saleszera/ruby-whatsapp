# `history`

Conversation history synced from the WhatsApp Business app when a number moves onto
Cloud API. It arrives in chunks, so `phase`, `chunk_order`, and `progress` are how you
track completeness.

`Whatsapp::Webhook::History` · confidence: **confirmed**

## Payload

```json
{ "field": "history",
  "value": {
    "messaging_product": "whatsapp",
    "metadata": { "display_phone_number": "15550783881", "phone_number_id": "106540352242922" },
    "history": [
      { "metadata": { "phase": 2, "chunk_order": 1, "progress": 50 },
        "threads": [
          { "id": "16505551234",
            "context": { "wa_id": "16505551234",
                         "user_id": "US.13491208655302741918",
                         "username": "pablomorales" },
            "messages": [
              { "from": "16505551234",
                "from_user_id": "US.13491208655302741918",
                "id": "wamid.HBg",
                "timestamp": "1749416383",
                "type": "text",
                "text": { "body": "Does it come in another color?" },
                "history_context": { "status": "DELIVERED" } }
            ] }
        ] }
    ] } }
```

Two `metadata` objects, and they are different things: the value-level one is the
ordinary business-phone-number `Metadata`, while each `history[]` entry has its own
carrying the sync counters.

## Value accessors

| Accessor | Type |
| --- | --- |
| `messaging_product` | `String` |
| `metadata` | `Metadata` — the business phone number, **not** the sync counters |
| `chunks` | `Array<History::Chunk>` |
| `phase` / `chunk_order` / `progress` | Read through to `chunks.first`, since a delivery normally carries one chunk |
| `contacts` | `Array<Contact>` — populated only by the media-asset variant |
| `messages` | `Array<Message::*>` — populated only by the media-asset variant |
| `raw` | The untouched `value` hash |

## Chunk accessors

| Accessor | Meaning |
| --- | --- |
| `phase` | Sync phase |
| `chunk_order` | This chunk's position within its phase |
| `progress` | Percent complete, 0–100 |
| `threads` | `Array<History::Thread>` |

## Thread accessors

| Accessor | Meaning |
| --- | --- |
| `id` | The thread identifier — the user's phone number, omitted for a username adopter |
| `context` | A `Contact` — `wa_id`, `user_id`, `parent_user_id`, `username` |
| `messages` | `Array<Message::*>`, dispatched by `type` like any inbound message |
| `raw` | The untouched thread hash |

`context` reuses the same [`Contact`](messages.md#value-accessors) as every other contact
entry: its `username` read already falls back to a flat key, which is where Meta puts it
here, and `profile_name` is simply `nil` since a thread context carries no profile.

Each synced message also has a `history_context.status` — its delivery state at sync
time. That is deliberately **not** modelled: it would put a history-only field on
`Message::Base`, the envelope shared by every inbound message type, where it could never
appear. Read it off `thread.raw`:

```ruby
thread.raw.dig("messages", 0, "history_context", "status")  # => "DELIVERED"
```

## Handling it

```ruby
when "history"
  sync = change.value

  sync.chunks.each do |chunk|
    chunk.threads.each do |thread|
      # A username adopter has no phone number here — the BSUID is the join key
      customer = Customer.find_or_create_by!(bsuid: thread.context&.user_id)
      customer.import_history!(thread.messages)
    end

    Importer.finish! if chunk.progress == 100
  end
```

> **Changed in 0.6.0.** `phase`/`chunk_order`/`progress` used to be read from
> `value["metadata"]` and threads from `value["threads"]` — one level too high, so every
> accessor was permanently empty. `threads` has moved onto `Chunk`, and the three
> counters now work.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
