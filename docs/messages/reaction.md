# Reaction Messages

Acknowledges a previous message with an emoji, mirroring WhatsApp's native
tap-and-hold reaction, without cluttering the thread with a new text message.

```ruby
Whatsapp::Messages.send_reaction!(to: "+15551234567", message_id: "wamid.HBg...", emoji: "👍")
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `message_id` | yes | The WAMID of the message being reacted to |
| `emoji` | yes | A single emoji, or `""` to remove |

`emoji` is checked against Ruby's `\p{Emoji}` property, so a plain word is rejected
locally rather than by Meta. `nil` is invalid; the empty string is not.

## Removing a reaction

Sending an empty `emoji` removes a reaction you previously sent to that message:

```ruby
Whatsapp::Messages.send_reaction!(to: "+15551234567", message_id: "wamid.HBg...", emoji: "")
```

## Serialized payload

```ruby
Whatsapp::Messages::Reaction.new(
  to: "+15551234567", message_id: "wamid.HBg...", emoji: "\u{1F44D}"
).serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "reaction",
#   reaction: { message_id: "wamid.HBg...", emoji: "👍" }
# }
```

The `reaction` hash is not compacted — both keys always ship, which is what makes the
empty-string removal work.

## Validation errors

```ruby
Whatsapp::Messages.send_reaction!(to: "+15551234567", message_id: "wamid.HBg...", emoji: "nope")
# => ActiveModel::ValidationError: Emoji must be a valid emoji character

Whatsapp::Messages.send_reaction!(to: "+15551234567", message_id: "wamid.HBg...", emoji: nil)
# => ActiveModel::ValidationError: Emoji can't be nil
```

`message_id` is checked for presence only — an existent-looking but wrong WAMID
surfaces server-side as error `131009`.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/reaction-messages>
