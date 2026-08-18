# `account_review_update`

The verdict on a WhatsApp Business Account review.

`Whatsapp::Webhook::AccountReviewUpdate` · confidence: **high** — one field, and Meta
documents it plainly

## Payload

```json
{ "field": "account_review_update", "value": { "decision": "APPROVED" } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `decision` | `APPROVED` or `REJECTED` |

## Handling it

```ruby
when "account_review_update"
  Account.find_by(waba_id: entry.id)&.update!(review_decision: change.value.decision)
```

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
