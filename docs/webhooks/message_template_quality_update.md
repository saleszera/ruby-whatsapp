# `message_template_quality_update`

A template's quality score changed. Quality is computed from how recipients react —
blocks, reports, and "not useful" feedback push it down. A template that reaches `RED`
gets paused, then eventually disabled, so a `GREEN → YELLOW` transition is your early
warning.

`Whatsapp::Webhook::MessageTemplateQualityUpdate` · confidence: **moderate-high**

## Payload

```json
{ "field": "message_template_quality_update",
  "value": {
    "message_template_id": "123",
    "message_template_name": "order_confirmation",
    "message_template_language": "en_US",
    "previous_quality_score": "GREEN",
    "new_quality_score": "YELLOW"
  } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `message_template_id` | The template's ID |
| `message_template_name` | Its name |
| `message_template_language` | Its locale |
| `previous_quality_score` | `GREEN` \| `YELLOW` \| `RED` \| `UNKNOWN` |
| `new_quality_score` | Same set |

## Handling it

```ruby
when "message_template_quality_update"
  update = change.value

  if update.new_quality_score == "RED"
    Ops.alert("Template #{update.message_template_name} dropped to RED — pause the campaign")
  end
```

The same score is readable on demand via
[`Response::Node#quality_score`](../message_templates/responses.md#qualityscore).

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
