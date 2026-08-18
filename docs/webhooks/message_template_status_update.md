# `message_template_status_update`

The review verdict on a template you submitted. This is **the** notification to handle
if you create templates from code — Meta reviews asynchronously and can take up to 24
hours, so this is how you learn the outcome without polling.

`Whatsapp::Webhook::MessageTemplateStatusUpdate` · confidence: **high**

## Payload

```json
{ "field": "message_template_status_update",
  "value": {
    "message_template_id": "123",
    "message_template_name": "order_confirmation",
    "message_template_language": "en_US",
    "event": "REJECTED",
    "reason": "INVALID_FORMAT"
  } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `message_template_id` | The template's ID, as returned by `create` |
| `message_template_name` | Its name |
| `message_template_language` | Its locale — a template is one per `(name, language)` pair |
| `event` | `APPROVED` \| `REJECTED` \| `PAUSED` \| `PENDING_DELETION` \| … |
| `reason` | Why it was rejected: `NONE` `ABUSIVE_CONTENT` `INVALID_FORMAT` `PROMOTIONAL` `TAG_CONTENT_MISMATCH` `SCAM` |

## Handling it

```ruby
when "message_template_status_update"
  update = change.value

  MessageTemplate
    .find_by(meta_id: update.message_template_id)
    &.update!(status: update.event, rejected_reason: update.reason)

  if update.event == "REJECTED"
    Rails.logger.warn(
      "Template #{update.message_template_name} (#{update.message_template_language}) " \
      "rejected: #{update.reason}"
    )
  end
```

See [../message_templates/README.md](../message_templates/README.md) for the creation
side.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
