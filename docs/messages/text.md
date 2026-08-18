# Text Messages

The default way to carry a conversational reply or notice. Most other kinds exist
because they need to express something plain text can't — media, buttons, structured
data.

```ruby
Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hello from ruby-whatsapp!")
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `body` | yes | Max **4096** characters |
| `preview_url` | no | `true` or `false`. **Defaults to `true`** |

`preview_url` controls whether WhatsApp renders a link preview card for the first URL
in the body. Turn it off for transactional messages where a preview would be noise:

```ruby
Whatsapp::Messages.send_text!(
  to: "+15551234567",
  body: "Track your order: https://example.com/orders/1234",
  preview_url: false
)
```

## Serialized payload

```ruby
Whatsapp::Messages::Text.new(to: "+15551234567", body: "Hello from ruby-whatsapp!").serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "text",
#   text: { body: "Hello from ruby-whatsapp!", preview_url: true }
# }
```

The `text` hash is deliberately **not** compacted, so `preview_url` is always present
on the wire even when it holds its default.

## Validation errors

```ruby
Whatsapp::Messages.send_text!(to: "+15551234567", body: "")
# => ActiveModel::ValidationError: Body can't be blank

Whatsapp::Messages.send_text!(to: "+15551234567", body: "x" * 4097)
# => ActiveModel::ValidationError: Body is too long (maximum is 4096 characters)
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/text-messages>
