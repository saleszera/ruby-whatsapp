# Document Messages

Shares a file — an invoice, a contract, a PDF — with an optional caption and the
filename the recipient sees.

```ruby
Whatsapp::Messages.send_document!(
  to: "+15551234567",
  link: "https://example.com/invoice.pdf",
  filename: "invoice.pdf"
)
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `id` | one of | A media ID from [`Media#upload`](../media/README.md) |
| `link` | one of | A publicly reachable HTTPS URL |
| `caption` | no | Max **1024** characters |
| `filename` | no | The name shown to the recipient; not validated |

**Either `id` or `link` is required.** Without `filename`, WhatsApp falls back to
whatever it can infer from the URL or media asset, which is usually an unhelpful
hash — set it whenever the recipient will save the file.

## Serialized payload

```ruby
Whatsapp::Messages::Document.new(
  to: "+15551234567", link: "https://example.com/invoice.pdf", filename: "invoice.pdf"
).serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "document",
#   document: { link: "https://example.com/invoice.pdf", filename: "invoice.pdf" }
# }
```

## Validation errors

```ruby
Whatsapp::Messages.send_document!(to: "+15551234567", filename: "invoice.pdf")
# => ActiveModel::ValidationError: Either id or link must be present
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/document-messages>
