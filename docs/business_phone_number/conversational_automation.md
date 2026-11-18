# Conversational Automation: Welcome Message, Ice Breakers, and Commands

**Conversational components** are in-chat helpers you switch on per business phone number:

- **Ice breakers** (`prompts`): up to 4 tappable strings, such as "Plan a trip", shown the first
  time a user opens a chat with you.
- **Commands** (`commands`): up to 30 `/commands`, each with a hint. A user sees them after
  typing `/` in the chat.
- **Welcome message** (`enable_welcome_message`): asks WhatsApp to notify you when a user opens a
  chat with no previous thread, so you can greet them. See [the caveat below](#the-welcome-message).

`Whatsapp::BusinessPhoneNumber::ConversationalAutomation` reads and writes all three.

> **Same `phone_id` as the onboarding actions.** Meta files this API under "WhatsApp Business
> Account", but both endpoints address the **phone number**, like [`Profile`](profile.md) and
> [`RequestCode`/`VerifyCode`/`Register`/`Deregister`](README.md).

```ruby
Whatsapp.configure do |config|
  config.api_key  = ENV.fetch("WHATSAPP_API_KEY")
  config.phone_id = ENV.fetch("WHATSAPP_PHONE_ID")
end

automation = Whatsapp::BusinessPhoneNumber::ConversationalAutomation

automation::Update.call(prompts: ["Book a flight", "Plan a vacation"])  # => #<Response success=true>
automation::Get.call.prompts                                            # => ["Book a flight", "Plan a vacation"]
```

| Method | Request | Returns |
| --- | --- | --- |
| `Get.call(client:)` | `GET /{phone_id}?fields=conversational_automation` | `ConversationalAutomation::Details` |
| `Update.call(client:, enable_welcome_message:, prompts:, commands:)` | `POST /{phone_id}/conversational_automation` | `BusinessPhoneNumber::Response` |

Meta documents **only these two operations**: no `PATCH`, `PUT`, or `DELETE`. `Update` is how
you create, change, *and* clear settings (see [Clearing settings](#clearing-settings)).

## Reading the configuration

```ruby
details = Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Get.call

details.id                        # => "106540352242922"  (the phone number ID)
details.prompts                   # => ["Find the best hotels in the area", "Find deals on rental cars"]
details.commands                  # => [{ "command_name" => "tickets", "command_description" => "Book flight tickets" }]
details.enable_welcome_message    # => true, false, or nil when Meta does not report it
details.welcome_message_enabled?  # => true only for a literal true
```

Meta returns this read as a *field* on the phone number node, not as a `GET` on the
`conversational_automation` edge, so the request is `GET /{phone_id}?fields=conversational_automation`.
`Details` unwraps the `conversational_automation` envelope. `prompts` and `commands` default to
`[]` when nothing is configured.

`commands` stay the **raw hashes Meta sent**. They are not validated `Command` objects, so a
limit Meta loosens later can never make a read fail, and you can send them straight back to
`Update` (string keys are accepted).

> Meta's current sample response omits `enable_welcome_message`, while older docs included
> it. Treat `nil` as "not reported", not as "disabled".

## Updating the configuration

```ruby
Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Update.call(
  enable_welcome_message: true,
  prompts: ["Book a flight", "Plan a vacation"],
  commands: [
    { command_name: "tickets", command_description: "Book flight tickets" },
    { command_name: "hotel",   command_description: "Book hotel" },
  ]
).success
# => true
```

Every field is optional, but at least one is required. An omitted field is **left out of the
payload**, never sent as `null`:

```ruby
Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Update.new(prompts: ["Book a flight"]).serialize
# => { prompts: ["Book a flight"] }
```

`commands` accepts hashes (symbol or string keys) or
`ConversationalAutomation::Command` instances, mixed freely:

```ruby
command = Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Command.new(
  command_name: "tickets", command_description: "Book flight tickets"
)
Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Update.call(commands: [command])
```

### Adding one command to the existing list

Each list you send is very likely **the whole list**, not something added to what's already
there (see [Unverified](#unverified-against-a-live-account)). To add a command, read the list
first and send it back with the new one:

```ruby
automation = Whatsapp::BusinessPhoneNumber::ConversationalAutomation

current = automation::Get.call.commands
automation::Update.call(commands: current + [{ command_name: "hotel", command_description: "Book hotel" }])
```

### Clearing settings

Meta documents no `DELETE`. Send `false` and empty arrays. Both are kept in the payload on
purpose:

```ruby
Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Update.new(
  enable_welcome_message: false, prompts: [], commands: []
).serialize
# => { enable_welcome_message: false, prompts: [], commands: [] }
```

### Validation

Every rule is checked **before** the request. A failure raises `ActiveModel::ValidationError`
and nothing is sent:

| Field | Rule |
| --- | --- |
| *(any)* | at least one of `enable_welcome_message`, `prompts`, `commands` |
| `enable_welcome_message` | `true` or `false`; a truthy value like `"true"` is rejected, not converted |
| `prompts` | an Array of at most **4** non-blank Strings, each at most **80** characters, no emoji |
| `commands` | an Array of at most **30**, with unique `command_name`s |
| `command_name` | a non-blank String, at most **32** characters, no leading `/`, no emoji |
| `command_description` | a non-blank String, at most **256** characters, no emoji |

```ruby
automation = Whatsapp::BusinessPhoneNumber::ConversationalAutomation

automation::Update.new
# => ActiveModel::ValidationError: at least one of enable_welcome_message, prompts, commands must be provided

automation::Update.new(prompts: %w[a b c d e])
# => ActiveModel::ValidationError: Prompts accepts at most 4 entries

automation::Update.new(prompts: ["Plan a trip ✈️"])
# => ActiveModel::ValidationError: Prompts entry at index 0 must not contain emoji

automation::Update.new(commands: [{ command_name: "/tickets", command_description: "Book" }])
# => ActiveModel::ValidationError: Commands contain an invalid command at index 0:
#    Command name must not start with "/"; WhatsApp adds it

automation::Update.new(commands: [{ command_name: "a", command_description: "x" },
                                  { command_name: "a", command_description: "y" }])
# => ActiveModel::ValidationError: Commands must have unique command names (duplicated: a)
```

A command that is malformed (a missing or unknown key, or neither a Hash nor a `Command`) is
reported the same way, as a `:commands` error naming its index. It never escapes as
`ArgumentError` or `TypeError`, so `valid?` never raises.

**About "no emoji".** Meta says emojis are not supported. The check catches anything *shown*
as an emoji: 👋, ✈️, flags, keycaps like 1️⃣. It lets through text symbols that are
technically emoji code points, such as `©`, `™`, `#`, so ordinary copy is never rejected. A
pictograph in its plain-text form (a bare `✈` with no variation selector) also gets through,
and Meta has the final say on it.

The leading `/` is rejected rather than silently removed. Meta documents command names as
"without leading slash", and WhatsApp adds the slash itself.

`Update` returns the same `Whatsapp::BusinessPhoneNumber::Response` as the onboarding actions.
The endpoint answers with a bare `{ "success": true }`.

## What arrives on your webhook

Nothing new to parse. A user tapping an ice breaker, or sending a command, reaches you as an
ordinary [`messages` webhook](../webhooks/messages.md) of `type: "text"`, deserialized as
`Whatsapp::Webhook::Message::Text`:

- **Ice breaker**: `text.body` is the prompt string, for example `"Plan a trip"`.
- **Command**: `text.body` is everything the user typed, for example `"/imagine cars racing on Mars"`.
  Matching the `/command` prefix is up to your app.

Tapping a `wa.me` / `api.whatsapp.com` link with pre-filled text hides the ice breakers.

### The welcome message

With `enable_welcome_message: true`, WhatsApp is supposed to send a `messages` webhook of
`type: "request_welcome"` the first time a user opens a chat with no prior thread. That
webhook opens a customer-service window for a free-form reply. Be aware:

- Meta's own docs said welcome messages were **"currently not functioning as intended"**, and
  the current guide has removed the section entirely. The API reference still accepts the
  flag.
- `request_welcome` is not in Meta's current `messages` webhook reference. This gem passes it
  through as `Whatsapp::Webhook::Message::Unknown` rather than raising.

## Errors

```ruby
Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Get.call
# => Whatsapp::BusinessPhoneNumber::Error: phone_id is required for the phone number node;
#    set it via Whatsapp.configure or Client.new(phone_id:)

Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Update.call(prompts: [])
# => Whatsapp::BusinessPhoneNumber::Error: phone_id is required for the
#    conversational_automation edge; set it via Whatsapp.configure or Client.new(phone_id:)

# non-2xx response
# => Whatsapp::BusinessPhoneNumber::Error: Failed to update conversational automation:
#    403 Forbidden - {"error":{"message":"Your app doesn't have permission to manage ..."}}
```

Both actions raise `Whatsapp::BusinessPhoneNumber::Error`, the same class the rest of the
module uses, so one `rescue` covers it all. See [../errors.md](../errors.md).

## Targeting a different number

Inject a client rather than changing the global configuration:

```ruby
Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Get.call(
  client: Whatsapp::Client.new(phone_id: "OTHER_PHONE_ID")
)
```

## Unverified against a live account

These specs are built from Meta's published docs, not a live account. Still open:

- whether a `POST` that leaves out a field really keeps its current value, and whether a list
  you send replaces the stored one (the gem assumes both, per Graph API convention)
- whether `[]` / `false` clear settings, as a third-party connector documents (Meta does not say)
- whether the `GET` still returns `enable_welcome_message`
- whether `request_welcome` is delivered at all today
- whether a `422` really means "the phone number isn't verified yet", as a third-party
  connector documents

## Not wrapped

- **`GET /{phone_id}/conversational_automation`**, the edge-form read. Only older docs show
  it. `Get` uses the documented `?fields=` form.
- **A typed `request_welcome` webhook message**, while Meta says the feature doesn't work.

---

**See also:** [Reading and updating the business profile](profile.md) ·
[Registering business phone numbers](README.md) · [Incoming messages](../webhooks/messages.md)

---

**Meta docs:**
<https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/conversational-automation-api> ·
<https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/conversational-components>
