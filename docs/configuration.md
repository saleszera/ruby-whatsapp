# Configuration

`Whatsapp.configure` sets the global defaults every `Whatsapp::Client` is built from.
Call it once at boot.

```ruby
Whatsapp.configure do |config|
  config.api_key  = ENV.fetch("WHATSAPP_API_KEY")
  config.phone_id = ENV.fetch("WHATSAPP_PHONE_ID")
end
```

## Options

| Option | Default | Needed for |
| --- | --- | --- |
| `api_key` | `nil` | Everything — a Meta system-user or app access token |
| `phone_id` | `nil` | [Messages](messages/README.md), [media](media/README.md), [phone-number onboarding](business_phone_number/README.md) |
| `waba_id` | `nil` | [Template management](message_templates/README.md), [subscribed apps](subscribed_app/README.md) |
| `verify_token` | `nil` | The [webhook GET handshake](webhooks/README.md#verification-the-get-handshake) |
| `app_secret` | `nil` | [Webhook signature verification](webhooks/README.md#signature-the-post-check) |
| `host` | `"https://graph.facebook.com"` | Overriding the API host |
| `version` | `"v24.0"` | Pinning a Graph API version |
| `media_host_allowlist` | `["lookaside.fbsbx.com", "mmg.whatsapp.net", "graph.facebook.com"]` | [Media download safety](media/README.md#the-token-never-leaves-the-allowlist) |

A full configuration:

```ruby
Whatsapp.configure do |config|
  config.api_key      = ENV.fetch("WHATSAPP_API_KEY")
  config.phone_id     = ENV.fetch("WHATSAPP_PHONE_ID")
  config.waba_id      = ENV.fetch("WHATSAPP_WABA_ID")
  config.verify_token = ENV.fetch("WHATSAPP_VERIFY_TOKEN")
  config.app_secret   = ENV.fetch("WHATSAPP_APP_SECRET")
end
```

In Rails, put that in `config/initializers/whatsapp.rb` and read from
`Rails.application.credentials` rather than `ENV`.

## Which ID addresses what

The most common source of confusion. Two different Meta objects, two different
permissions:

```
phone_id  ──►  Messages          send_text!, send_template!, send_interactive!, ...
               Media             upload, get_url, download, delete
               BusinessPhoneNumber  RequestCode, VerifyCode, Register, Deregister
               (permission: whatsapp_business_messaging)

waba_id   ──►  MessageTemplates  create, list, find, update, delete, upsert
               SubscribedApp     List, Subscribe, Unsubscribe
               (permission: whatsapp_business_management)
```

Calling a `waba_id` API without one raises before any request is made:

```ruby
Whatsapp::MessageTemplates.new.list
# => Whatsapp::MessageTemplates::TemplateError: waba_id is required for template
#    management; set it via Whatsapp.configure or Client.new(waba_id:)
```

## Secrets are redacted

`api_key`, `app_secret`, and `verify_token` never appear in `#inspect` output — not on
`Configuration`, not on `Client`, and therefore not on anything holding a client
(`Media`, `MessageTemplates`). This matters because error trackers routinely capture
local variables.

```ruby
Whatsapp.configuration.inspect
# => "#<Whatsapp::Configuration host=\"https://graph.facebook.com\" version=\"v24.0\"
#     api_key=[REDACTED] phone_id=\"106540352242922\" waba_id=nil
#     verify_token=[REDACTED] app_secret=[REDACTED]>"

Whatsapp::Client.new.inspect
# => "#<Whatsapp::Client host=\"https://graph.facebook.com\" version=\"v24.0\"
#     api_key=[REDACTED] phone_id=\"106540352242922\" waba_id=nil>"
```

The same treatment applies to credentials in transit:
[`Register#inspect`](business_phone_number/README.md#registering) redacts the PIN and
`VerifyCode#inspect` redacts the OTP.

## The client

Every API call goes through a `Whatsapp::Client`, which wraps a persistent HTTP
connection. All its constructor keywords default to `Whatsapp.configuration`:

```ruby
Whatsapp::Client.new(
  host:     Whatsapp.configuration.host,
  version:  Whatsapp.configuration.version,
  api_key:  Whatsapp.configuration.api_key,
  phone_id: Whatsapp.configuration.phone_id,
  waba_id:  Whatsapp.configuration.waba_id,
  timeout:  30,     # Client::DEFAULT_TIMEOUT, seconds
  logger:   nil
)
```

Every entry point in the gem accepts an optional `client:`, which is how you address a
second phone number or business account without touching global state:

```ruby
Whatsapp::Messages.send_text!(
  to: "+15551234567", body: "Hi",
  client: Whatsapp::Client.new(phone_id: "OTHER_PHONE_ID")
)

Whatsapp::MessageTemplates.new(client: Whatsapp::Client.new(waba_id: "OTHER_WABA_ID")).list
```

### Connection reuse

`Client#connection` memoizes `HTTP.persistent(host)`, so successive calls on the same
client reuse one TCP connection. Build a client once and hold it for a batch of sends
rather than constructing one per message:

```ruby
client = Whatsapp::Client.new

recipients.each { |to| Whatsapp::Messages.send_text!(to:, body: "Hi", client:) }
```

### Timeouts

```ruby
Whatsapp::Client.new(timeout: 10)
```

Applies to the whole request. The default is 30 seconds.

## Instrumentation

Pass a `Logger` to log every request and response:

```ruby
client = Whatsapp::Client.new(logger: Logger.new($stdout))

Whatsapp::Messages.send_text!(to: "+15551234567", body: "Hi", client: client)
# I, [...]  INFO -- : POST https://graph.facebook.com/v24.0/106540352242922/messages
# I, [...]  INFO -- : 200 OK
```

| Event | Logged |
| --- | --- |
| Request start | `<VERB> <url>` at `info` |
| Response | `<status> <reason>` at `info` |
| Error | `<name>: <message>` at `error` |

> **The query string is deliberately dropped.** Media and template endpoints put IDs
> in query parameters; logging them whole is how identifiers end up in log aggregators
> forever. Only the path is logged.

In Rails, pass `Rails.logger`:

```ruby
Whatsapp::Client.new(logger: Rails.logger)
```

---

See also [errors.md](errors.md) for what the client raises.
