# `message_template_components_update`

A template's components changed — usually because Meta edited it, or because an edit
you submitted was applied.

`Whatsapp::Webhook::MessageTemplateComponentsUpdate` · confidence: **moderate**

## Payload

```json
{ "field": "message_template_components_update",
  "value": {
    "message_template_id": "123",
    "message_template_name": "order_confirmation",
    "message_template_language": "en_US",
    "message_template_element": "BODY"
  } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `message_template_id` | The template's ID |
| `message_template_name` | Its name |
| `message_template_language` | Its locale |
| `message_template_element` | Which component changed |

## Handling it

The notification says *that* something changed, not what it changed to. Re-read the
template to get the new shape:

```ruby
when "message_template_components_update"
  node = Whatsapp::MessageTemplates.new.find(template_id: change.value.message_template_id)
  MessageTemplate.find_by(meta_id: node.id)&.update!(components: node.components)
```

> **Best-effort schema.** Meta describes this field in one line and publishes no JSON
> example. Validate against a real payload (App Dashboard → "send test payload")
> before depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
