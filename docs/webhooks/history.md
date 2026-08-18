# `history`

Conversation history synced from the WhatsApp Business app when a number moves onto
Cloud API. It arrives in chunks, so `phase`, `chunk_order`, and `progress` are how you
track completeness.

`Whatsapp::Webhook::History` · confidence: **low**

## Payload

```json
{ "field": "history",
  "value": { "metadata": { "phase": 1, "chunk_order": 1, "progress": 50 },
             "threads": [{ "id": "thread.1" }] } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `phase` | Sync phase (dug from `value.metadata`) |
| `chunk_order` | This chunk's position (dug from `value.metadata`) |
| `progress` | Percent complete, 0–100 (dug from `value.metadata`) |
| `threads` | **Raw Array** of thread hashes |

Note the three scalars are flattened up from the nested `metadata` object, while
`threads` is left raw — its element shape is undocumented.

## Handling it

```ruby
when "history"
  sync = change.value

  HistoryChunk.create!(phase: sync.phase, order: sync.chunk_order, threads: sync.threads)
  Importer.finish! if sync.progress == 100
```

> **Best-effort schema, low confidence.** Validate against a real payload before
> depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
