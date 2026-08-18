# Mark Message As Read

Closes the read-receipt loop — this is what turns on the blue "seen" checkmarks on the
customer's side. Marking one message read also marks **every earlier message in that
conversation** as read.

```ruby
Whatsapp::Messages.mark_message_as_read!(
  message_id: "wamid.HBgLMTY1MDM4Nzk0MzkVAgARGBJDQjZCMzlEQUE4OTJBMTE4RTUA"
)
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `message_id` | yes | The WAMID of an inbound message |
| `client` | no | Defaults to a new `Whatsapp::Client` |

`message_id` is checked for presence only — there is no WAMID format check, so an
invalid ID surfaces server-side as error `131009`.

> **30-day window.** Meta requires the call within 30 days of receiving the message.
> Past that, the request fails.

## Why it isn't a `send_<kind>!` method

Every other kind shares the `to` / `recipient_type` / `type` envelope from
`Messages::Base`. This endpoint's payload is flat — no recipient, no type — so
`MarkMessageAsRead` doesn't inherit `Base` at all and isn't registered in
`Messages::KINDS`. Rather than carve an exception into the loop that generates
`send_<kind>!` methods, it gets its own hand-written class method.

## Serialized payload

```ruby
Whatsapp::Messages::MarkMessageAsRead.new(message_id: "wamid.HBg...").serialize
# => { messaging_product: "whatsapp", status: "read", message_id: "wamid.HBg..." }
```

## The response

This endpoint replies `{"success": true}` rather than the usual
`{messaging_product, contacts, messages}`, so the shared `Messages::Response` carries
it on `#success`:

```ruby
result = Whatsapp::Messages.mark_message_as_read!(message_id: "wamid.HBg...")

result.success   # => true
result.messages  # => []  — nothing to report for this endpoint
result.contacts  # => []
```

## Errors

```ruby
Whatsapp::Messages::MarkMessageAsRead.new(message_id: "")
# => ActiveModel::ValidationError: Message can't be blank
```

A non-2xx response raises `Whatsapp::RequestError: Failed to mark message as read: ...`.

## Typical use

Call it from your webhook handler as soon as an inbound message is deserialized:

```ruby
notification.entry.each do |entry|
  entry.changes.each do |change|
    next unless change.field == "messages"

    change.value.messages.each do |message|
      Whatsapp::Messages.mark_message_as_read!(message_id: message.id)
    end
  end
end
```

See [../webhooks/messages.md](../webhooks/messages.md) for the inbound side.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/mark-message-as-read>
