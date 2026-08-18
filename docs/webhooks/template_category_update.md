# `template_category_update`

Meta reclassified a template — most often moving something you filed as `UTILITY` into
`MARKETING`. This matters because category determines **how you are billed** and
whether the message is subject to marketing opt-outs.

`Whatsapp::Webhook::TemplateCategoryUpdate` · confidence: **moderate-high**

## Payload

```json
{ "field": "template_category_update",
  "value": {
    "message_template_id": "123",
    "message_template_name": "order_confirmation",
    "message_template_language": "en_US",
    "previous_category": "MARKETING",
    "new_category": "UTILITY",
    "correct_category": "UTILITY"
  } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `message_template_id` | The template's ID |
| `message_template_name` | Its name |
| `message_template_language` | Its locale |
| `previous_category` | What it was |
| `new_category` | What it is now |
| `correct_category` | What Meta believes it should be |

## Handling it

```ruby
when "template_category_update"
  update = change.value

  MessageTemplate
    .find_by(meta_id: update.message_template_id)
    &.update!(category: update.new_category)

  Billing.recheck!(update.message_template_name) if update.new_category == "MARKETING"
```

> **Best-effort schema.** Meta publishes no JSON example for this field. Validate
> against a real payload before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
