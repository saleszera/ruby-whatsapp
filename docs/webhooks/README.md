# Webhooks

Meta pushes inbound messages, delivery statuses, and ~18 other account and template
notifications to a callback URL you register. This directory covers the *inbound*
direction — the opposite of everything under [../messages/](../messages/README.md).

> **Two different things.** `Whatsapp::Webhook` deserializes notifications once Meta is
> already sending them. Turning that delivery **on** for a WhatsApp Business Account is
> [`Whatsapp::SubscribedApp`](../subscribed_app/README.md). You need both.

## Install (Rails)

```bash
bundle exec rake whatsapp:install:webhook
```

This copies a personalizable controller to
`app/controllers/whatsapp/webhooks_controller.rb` — it never overwrites an existing
one — and prints the routes and configuration you still need to add by hand:

```ruby
# config/routes.rb
get  "/whatsapp/webhooks", to: "whatsapp/webhooks#verify"
post "/whatsapp/webhooks", to: "whatsapp/webhooks#receive"

# config/initializers/whatsapp.rb
Whatsapp.configure do |config|
  config.verify_token = Rails.application.credentials.whatsapp_verify_token
  config.app_secret   = Rails.application.credentials.whatsapp_app_secret
end
```

The rake task is registered by `Whatsapp::Railtie` and only exists inside a Rails app.
Outside Rails, call the installer directly — it is plain Ruby with no Rails dependency:

```ruby
Whatsapp::Webhook::Installer.call(root: Dir.pwd)   # => :created | :skipped
```

## The generated controller

Yours to edit. It handles the handshake and the signature check, then deserializes
every notification into typed objects and leaves a `# TODO` where your handling goes:

```ruby
class Whatsapp::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def verify
    challenge = Whatsapp::Webhook::Verification.call(params: params)
    challenge ? render(plain: challenge) : head(:forbidden)
  end

  def receive
    raw_body = request.body.read
    return head(:unauthorized) unless Whatsapp::Webhook::Signature.valid?(
      payload: raw_body, header: request.headers["X-Hub-Signature-256"]
    )

    notification = Whatsapp::Webhook::Notification.deserialize(JSON.parse(raw_body))
    # notification.entry.each { |entry| entry.changes.each { |change| WebhookJob.perform_later(change) } }

    head :ok
  end
end
```

> **Answer fast, work later.** Meta retries a notification that doesn't get a 2xx
> quickly. Enqueue the work; don't do it inline.

## Verification (the GET handshake)

When you register the callback URL, Meta calls it once with `hub.mode`,
`hub.verify_token`, and `hub.challenge`. Echo the challenge back if the token matches:

```ruby
Whatsapp::Webhook::Verification.call(params: params)
# => "1158201444" — the challenge, to render as plain text
# => nil          — mode wasn't "subscribe", or the token didn't match
```

The token comparison uses `ActiveSupport::SecurityUtils.secure_compare`. A nil or empty
configured `verify_token` always returns `nil` rather than accepting anything.

## Signature (the POST check)

Every notification carries an `X-Hub-Signature-256` header: HMAC-SHA256 of the **raw
request body** using your app secret.

```ruby
Whatsapp::Webhook::Signature.valid?(payload: raw_body, header: request.headers["X-Hub-Signature-256"])
# => true | false
```

> **Use the raw body, not `params`.** Re-serializing a parsed hash changes the bytes
> and the signature will never match.

Returns `false` — never raises — for a nil payload, a missing or empty header, or a
missing app secret.

## Multi-tenant apps

Both take the credential as an overridable keyword, defaulting to
`Whatsapp.configuration`. That override is the multi-tenant path: an app serving many
customers, each with their own Meta App, resolves the account first and passes its
credentials explicitly.

```ruby
account = Account.find_by!(slug: params[:account_slug])

Whatsapp::Webhook::Verification.call(params:, verify_token: account.verify_token)
Whatsapp::Webhook::Signature.valid?(payload: raw_body, header:, app_secret: account.app_secret)
```

## The notification tree

```
{ object, entry: [ { id, changes: [ { field, value } ] } ] }
```

```ruby
notification = Whatsapp::Webhook::Notification.deserialize(JSON.parse(raw_body))

notification.object                      # => "whatsapp_business_account"
notification.entry.first.id              # => "102290129340398"  — the WABA ID
change = notification.entry.first.changes.first
change.field                             # => "messages"
change.value                             # => #<Whatsapp::Webhook::Messages ...>
```

`change.field` is one of Meta's 19 documented field names; `change.value` is that
field's deserialized payload, resolved through a frozen `Change::FIELDS` registry —
**never `const_get` on the field name**, since it comes straight off the internet.

A field not in the registry (something Meta adds after this gem ships) falls back to
`UnknownField` rather than raising, so your controller never 500s on an unrecognized
notification:

```ruby
change.value                # => #<Whatsapp::Webhook::UnknownField ...>
change.value["some_key"]    # reach into the raw hash
change.value.to_h           # the whole thing
```

## The 19 fields

| Field | Page | Confidence |
| --- | --- | --- |
| `messages` | [messages.md](messages.md) | **Confirmed** — Meta publishes a real payload |
| `account_alerts` | [account_alerts.md](account_alerts.md) | Moderate |
| `account_review_update` | [account_review_update.md](account_review_update.md) | High |
| `account_update` | [account_update.md](account_update.md) | Moderate |
| `automatic_events` | [automatic_events.md](automatic_events.md) | Low |
| `business_capability_update` | [business_capability_update.md](business_capability_update.md) | Moderate |
| `history` | [history.md](history.md) | Low |
| `message_template_components_update` | [message_template_components_update.md](message_template_components_update.md) | Moderate |
| `message_template_quality_update` | [message_template_quality_update.md](message_template_quality_update.md) | Moderate-high |
| `message_template_status_update` | [message_template_status_update.md](message_template_status_update.md) | High |
| `partner_solutions` | [partner_solutions.md](partner_solutions.md) | Low |
| `payment_configuration_update` | [payment_configuration_update.md](payment_configuration_update.md) | Moderate |
| `phone_number_name_update` | [phone_number_name_update.md](phone_number_name_update.md) | Moderate-high |
| `phone_number_quality_update` | [phone_number_quality_update.md](phone_number_quality_update.md) | Moderate |
| `security` | [security.md](security.md) | Low |
| `smb_app_state_sync` | [smb_app_state_sync.md](smb_app_state_sync.md) | Low-moderate |
| `smb_message_echoes` | [smb_message_echoes.md](smb_message_echoes.md) | Moderate |
| `template_category_update` | [template_category_update.md](template_category_update.md) | Moderate-high |
| `user_preferences` | [user_preferences.md](user_preferences.md) | Moderate |

> **On confidence.** Only `messages` has a Meta-published JSON example. The other 18
> field classes are reconstructed from the one-line descriptions in Meta's docs plus
> general Cloud API knowledge. They are real, tested classes — but validate one against
> a real payload (App Dashboard → "send test payload") before depending on it in
> production.

## Dispatching

`Change#field` is a plain String, which makes a `case` the natural handler:

```ruby
notification.entry.each do |entry|
  entry.changes.each do |change|
    case change.field
    when "messages"
      change.value.messages.each { |m| handle_message(m) }
      change.value.statuses.each { |s| handle_status(s) }
    when "message_template_status_update"
      Template.find_by(meta_id: change.value.message_template_id)
              &.update!(status: change.value.event)
    else
      Rails.logger.info("Unhandled webhook field: #{change.field}")
    end
  end
end
```

## Conventions

Every class here follows the read-side pattern — no validations, no `serialize`, just
a class-level `.deserialize(data)`:

1. Plain Ruby object, `attr_accessor` per field.
2. `.deserialize(data)` tolerates a nil or partial hash (`data ||= {}`) and missing
   arrays (`Array(data["key"]).map { ... }`).
3. Optional nested objects return `nil` when their source key is absent, not an
   all-nil instance — e.g. `Message::Context.deserialize(nil) # => nil`.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview>
