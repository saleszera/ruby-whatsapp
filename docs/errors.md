# Errors

Every exception this gem raises descends from `Whatsapp::Error`, so one rescue catches
the lot:

```ruby
begin
  Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hi")
rescue Whatsapp::Error => e
  Rails.logger.error("WhatsApp call failed: #{e.message}")
end
```

## The hierarchy

```
StandardError
└── Whatsapp::Error
    ├── Whatsapp::RequestError                              a message send failed
    ├── Whatsapp::Messages::PayloadError                    unknown message kind
    ├── Whatsapp::Messages::Interactive::Header::HeaderError  malformed interactive header
    ├── Whatsapp::Media::MediaError                         any Media failure
    ├── Whatsapp::MessageTemplates::TemplateError           any template-management failure
    ├── Whatsapp::SubscribedApp::Error                      any subscribed-apps failure
    └── Whatsapp::BusinessPhoneNumber::Error                any phone-number-onboarding failure
```

Each module raises **its own** error class rather than the generic
`Whatsapp::RequestError`, so you can rescue narrowly:

```ruby
rescue Whatsapp::MessageTemplates::TemplateError => e
  # a template problem specifically — retry, or surface to the operator
end
```

> **`Whatsapp::Webhook::Error` is not an exception.** Despite the name, it is a value
> object modelling Meta's error payloads on `Status#errors` and
> `Message::Unknown#errors`. See
> [webhooks/messages.md](webhooks/messages.md#errors).

## Validation errors are different

Local validation failures raise **`ActiveModel::ValidationError`**, not a gem class.
That is deliberate: a validation failure means *you* built something wrong, before any
network call happened, and ActiveModel's error object carries the per-attribute
detail.

```ruby
Whatsapp::Messages.send_text!(to: "+15551234567", body: "x" * 5000)
# => ActiveModel::ValidationError: Validation failed:
#    Body is too long (maximum is 4096 characters)
```

Reach the structured detail through the exception's model:

```ruby
begin
  Whatsapp::Messages.send_image!(to: "+15551234567", caption: "x" * 2000)
rescue ActiveModel::ValidationError => e
  e.model.errors.full_messages
  # => ["Either id or link must be present", "Caption is too long (maximum is 1024 characters)"]
  e.model.errors[:caption]
  # => ["is too long (maximum is 1024 characters)"]
end
```

Because every class runs `validate!` at the end of `initialize`, this raises at
**construction** time — the client is never touched.

Rescuing both kinds:

```ruby
begin
  Whatsapp::Messages.send_template!(to:, name:, language: { code: })
rescue ActiveModel::ValidationError => e
  # our payload is wrong — a bug, or bad user input
rescue Whatsapp::Error => e
  # Meta said no, or the network did
end
```

## Missing keywords

A required Ruby keyword that isn't supplied raises `ArgumentError`, not a validation
error — it never reaches the validator:

```ruby
Whatsapp::Messages.send_text!(body: "Hi")
# => ArgumentError: missing keyword: :to
```

## API failures

Any non-2xx response raises the owning module's error class with a consistent message
shape:

```
Failed to <action>: <status> - <body>
```

```ruby
# => Whatsapp::RequestError: Failed to send message: 400 Bad Request -
#    {"error":{"message":"(#131009) Parameter value is not valid","code":131009}}

# => Whatsapp::Media::MediaError: Failed to upload media: 401 Unauthorized - {...}

# => Whatsapp::MessageTemplates::TemplateError: Failed to create template:
#    400 Bad Request - {"error":{"message":"Invalid parameter","code":100}}
```

The response body is truncated at **500** characters, with `… (truncated)` appended —
Meta's error bodies can be long, and a full one in an exception message tends to end up
somewhere it shouldn't.

Actions used in these messages: `send message`, `mark message as read`,
`upload media`, `get media URL`, `download media`, `delete media`,
`list subscribed apps`, `subscribe app`, `unsubscribe app`,
`request verification code`, `verify code`, `register business phone number`,
`deregister business phone number`, plus the template CRUD verbs.

## Missing configuration

The `waba_id` and `phone_id` modules check for their ID **before** building a request,
and say exactly how to supply it:

```ruby
Whatsapp::MessageTemplates.new.list
# => Whatsapp::MessageTemplates::TemplateError: waba_id is required for template
#    management; set it via Whatsapp.configure or Client.new(waba_id:)

Whatsapp::SubscribedApp::List.call
# => Whatsapp::SubscribedApp::Error: waba_id is required for subscribed apps;
#    set it via Whatsapp.configure or Client.new(waba_id:)

Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834")
# => Whatsapp::BusinessPhoneNumber::Error: phone_id is required for the register edge;
#    set it via Whatsapp.configure or Client.new(phone_id:)
```

See [configuration.md](configuration.md#which-id-addresses-what).

## Argument errors from a module

Some misuse is caught before validation and raises the module's own error rather than
`ActiveModel::ValidationError` — these are wrong *calls*, not wrong *data*:

```ruby
templates.upsert(name: "x", language: "en_US", ...)
# => TemplateError: #upsert requires `languages:` (an array of locale codes);
#    use #create for a single one

templates.update(template_id: "123")
# => TemplateError: nothing to update: pass category, components or message_send_ttl_seconds

templates.delete(hsm_ids: %w[1 2], name: "x")
# => TemplateError: hsm_ids cannot be combined with name or hsm_id

Whatsapp::Messages.new(kind: :telepathy, payload: { to: "+1" })
# => Whatsapp::Messages::PayloadError: Unknown message kind: :telepathy.
#    Known kinds: text, image, audio, video, document, sticker, contacts, reaction,
#    location, address, location_request, template, interactive
```

## Interactive header errors

`Interactive::Header` raises `HeaderError` rather than adding a validation error,
because a header missing its content cannot be serialized at all:

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567", type: :reply_buttons, body: "Pick one",
  header: { type: "image" },
  action: { buttons: [{ id: "a", title: "A" }] }
)
# => Whatsapp::Messages::Interactive::Header::HeaderError:
#    Image link is required for image header
```

## Retrying

Meta's transient failures are ordinary HTTP: 429 for rate limiting, 5xx for outages.
The gem does not retry — that policy belongs to your job queue:

```ruby
class SendWhatsappJob < ApplicationJob
  retry_on Whatsapp::RequestError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveModel::ValidationError   # our payload is wrong; retrying won't fix it

  def perform(to:, body:)
    Whatsapp::Messages.send_text!(to:, body:)
  end
end
```

Discarding on `ActiveModel::ValidationError` is the important half: a locally invalid
payload will fail identically on every attempt.

> **Rate limits worth knowing.** Template edits are capped at 10 per 30 days and 1 per
> 24 hours; `Register`/`Deregister` at 10 per number per 72-hour window (error
> `133016`). None is observable client-side — they arrive as API errors.
