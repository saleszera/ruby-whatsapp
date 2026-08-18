# `smb_message_echoes`

Echoes of messages sent **from the WhatsApp Business app** rather than through the API.
Without this, a number used by both your code and a human agent in the app would show
you only half the conversation.

`Whatsapp::Webhook::SmbMessageEchoes` · confidence: **moderate**

## Payload

```json
{ "field": "smb_message_echoes",
  "value": { "messaging_product": "whatsapp",
             "metadata": { "display_phone_number": "15550783881",
                           "phone_number_id": "106540352242922" },
             "message_echoes": [{ "from": "15550783881",
                                  "type": "text",
                                  "text": { "body": "Thanks for shopping with us!" } }] } }
```

## Accessors

| Accessor | Type |
| --- | --- |
| `messaging_product` | `"whatsapp"` |
| `metadata` | `Metadata` — `display_phone_number`, `phone_number_id` |
| `message_echoes` | `Array<Message::*>` |

`message_echoes` reuses the same `Message.deserialize` dispatcher as
[`messages`](messages.md), so every echoed message is a fully typed `Message::Text`,
`Message::Image`, and so on — with the same accessors.

## Handling it

```ruby
when "smb_message_echoes"
  change.value.message_echoes.each do |echo|
    Conversation.for(echo.from).messages.create!(
      wamid: echo.id, direction: :outbound, source: :business_app, body: echo.try(:body)
    )
  end
```

Note `from` is *your* business number here, not the customer's — these are messages
you sent.

> **Moderate confidence on structure, low on the key name.** Meta states these mirror
> the standard message shape, which is why `Message.deserialize` is reused, but the
> exact `message_echoes` key is unverified. Validate against a real payload before
> depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
