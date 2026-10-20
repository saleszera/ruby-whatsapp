# `smb_message_echoes`

Echoes of messages sent **from the WhatsApp Business app** rather than through the API.
Without this, a number used by both your code and a human agent in the app would show
you only half the conversation. Messages the business *revoked* or *edited* from the app
arrive here too.

`Whatsapp::Webhook::SmbMessageEchoes` · confidence: **high**

## Payload

```json
{ "field": "smb_message_echoes",
  "value": {
    "messaging_product": "whatsapp",
    "metadata": { "display_phone_number": "15550783881", "phone_number_id": "106540352242922" },
    "contacts": [
      { "profile": { "username": "pablomorales" },
        "wa_id": "16505551234",
        "user_id": "US.13491208655302741918" }
    ],
    "message_echoes": [
      { "from": "15550783881",
        "to": "16505551234",
        "to_user_id": "US.13491208655302741918",
        "id": "wamid.HBg",
        "timestamp": "1750030073",
        "type": "text",
        "text": { "body": "Thanks for shopping with us!" } }
    ] } }
```

## Accessors

| Accessor | Type |
| --- | --- |
| `messaging_product` | `"whatsapp"` |
| `metadata` | `Metadata` — `display_phone_number`, `phone_number_id` |
| `contacts` | `Array<Contact>` — the customers these went to |
| `message_echoes` | `Array<SmbMessageEchoes::Echo>` |
| `raw` | The untouched `value` hash |

### `Echo`

| Accessor | Meaning |
| --- | --- |
| `to` | The customer's phone number, or `nil` once they adopt a username |
| `to_user_id` | Their [BSUID](messages.md#business-scoped-user-ids-bsuid) |
| `to_parent_user_id` | Their parent BSUID, present only if enrolled |
| `message` | The echoed `Message::*`, dispatched by `type` |

`Echo#message` goes through the same `Message.deserialize` dispatcher as
[`messages`](messages.md), so an echo is a fully typed `Message::Text`, `Message::Image`,
`Message::Revoke`, `Message::Edit`, and so on — with the same accessors.

Why a wrapper rather than three more accessors on `Message::Base`? Because an *inbound*
message can never carry a recipient. Putting `to`/`to_user_id`/`to_parent_user_id` on the
envelope shared by every message type would hand fifteen classes three permanently-`nil`
readers, and would turn the `NoMethodError` that currently tells you `message.to` is
meaningless into a silent `nil`.

## Handling it

```ruby
when "smb_message_echoes"
  change.value.message_echoes.each do |echo|
    # The customer may have no phone number; the BSUID always identifies them
    conversation = Conversation.for(bsuid: echo.to_user_id, wa_id: echo.to)

    conversation.messages.create!(
      wamid: echo.message.id,
      direction: :outbound,
      source: :business_app,
      body: echo.message.try(:body)
    )
  end
```

Note `echo.message.from` is *your* business number, not the customer's — these are
messages you sent. The customer is on `echo.to*`.

> **Changed in 0.6.0.** `message_echoes` used to be an `Array<Message::*>` directly;
> each entry is now an `Echo` wrapping that message, so `echo.body` becomes
> `echo.message.body`. The wrapper is what carries the new recipient identifiers.

> The `message_echoes` key itself is still inferred from the field name rather than
> confirmed by a published example — hence `raw`, so a drifted key leaves a trace.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
