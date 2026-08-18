# Managing Subscribed Apps

Before your app receives any [webhook](../webhooks/README.md) notifications for a
WhatsApp Business Account, it has to be **subscribed** to it.
`Whatsapp::SubscribedApp` wraps the `subscribed_apps` edge — the switch that turns
webhook delivery on or off.

> **Two halves of one thing.** This module makes Meta start sending;
> [`Whatsapp::Webhook`](../webhooks/README.md) deserializes what arrives. Neither is
> useful without the other.

Addresses your **WhatsApp Business Account** (`waba_id`, not `phone_id`) and needs the
`whatsapp_business_management` permission — same as
[template management](../message_templates/README.md).

```ruby
Whatsapp.configure do |config|
  config.api_key = ENV.fetch("WHATSAPP_API_KEY")
  config.waba_id = ENV.fetch("WHATSAPP_WABA_ID")
end

Whatsapp::SubscribedApp::Subscribe.call            # start webhook delivery
Whatsapp::SubscribedApp::List.call.map(&:name)     # => ["My App"]
Whatsapp::SubscribedApp::Unsubscribe.call          # stop it
```

| Method | Request | Returns |
| --- | --- | --- |
| `List.call(client:, fields:)` | `GET /{waba_id}/subscribed_apps` | `Response::Collection` |
| `Subscribe.call(client:, override_callback_uri:, verify_token:)` | `POST /{waba_id}/subscribed_apps` | `Response::Subscription` |
| `Unsubscribe.call(client:)` | `DELETE /{waba_id}/subscribed_apps` | `Response::Unsubscription` |

Three independent actions, so three classes rather than one class with three methods —
unlike [templates](../message_templates/README.md), subscribing and listing share no
identity or validation rules that would justify combining them.

## Subscribing

```ruby
result = Whatsapp::SubscribedApp::Subscribe.call

result.success       # => true
result.map(&:name)   # => ["My App"] — every app now subscribed, Meta's own echo
```

`Response::Subscription` is `Enumerable` over the same `Response::App` objects `List`
returns, so you can check the result without a second request.

### Per-WABA callback overrides

Tech Providers routing several WABAs' notifications to different callback URLs pass an
override instead of relying on the single callback URL configured on the app itself:

```ruby
Whatsapp::SubscribedApp::Subscribe.call(
  override_callback_uri: "https://example.com/webhooks/acme_corp",
  verify_token: "a-per-account-secret"
)
```

Both are optional and compacted out of the request body when absent. The
`verify_token` you pass here is the one Meta will send in the
[GET handshake](../webhooks/README.md#verification-the-get-handshake) for that WABA —
pass the matching value to `Verification.call(verify_token:)`.

> No client-side format check is applied to `override_callback_uri`. Meta enforces it
> server-side, and this gem validates only what Meta documents as a client-side rule.

## Listing

```ruby
apps = Whatsapp::SubscribedApp::List.call

apps.map(&:name)   # Collection is Enumerable
apps.first.id      # => "123456789"
apps.first.link    # => "https://www.facebook.com/games/?app_id=..."
apps.first.override_callback_uri  # => nil, or the per-WABA override
```

Restrict what comes back with `fields:` — an Array or a String, comma-joined for you:

```ruby
Whatsapp::SubscribedApp::List.call(fields: %w[id name])
Whatsapp::SubscribedApp::List.call(fields: "id,name")
```

`Response::App` flattens Meta's `whatsapp_business_api_data` wrapper, so `id`, `name`,
and `link` sit directly on the object rather than a nested hash.

> No pagination — Meta documents none for this edge, and an account typically has very
> few subscribed apps.

## Unsubscribing

```ruby
Whatsapp::SubscribedApp::Unsubscribe.call.success   # => true
```

Stops **all** webhook deliveries for this WABA immediately.

## Response shapes

Three actions, three genuinely different shapes — hence three classes:

| Class | Holds | From |
| --- | --- | --- |
| `Response::Collection` | `data: [App]`, `Enumerable` | `List` |
| `Response::Subscription` | `success`, `data: [App]`, `Enumerable` | `Subscribe` |
| `Response::Unsubscription` | `success` | `Unsubscribe` |

`Response::App` — `id`, `name`, `link`, `override_callback_uri` — is composed by both
`Collection` and `Subscription` rather than duplicated.

`success` is a strict `response["success"] == true`, so it is never a truthy string
you have to second-guess.

## Errors

```ruby
Whatsapp::SubscribedApp::Subscribe.call
# => Whatsapp::SubscribedApp::Error: waba_id is required for subscribed apps;
#    set it via Whatsapp.configure or Client.new(waba_id:)

# non-2xx response
# => Whatsapp::SubscribedApp::Error: Failed to subscribe app: 400 Bad Request - {...}
```

Every action raises `Whatsapp::SubscribedApp::Error` — never the generic
`Whatsapp::RequestError`. See [../errors.md](../errors.md).

## Targeting a different account

```ruby
Whatsapp::SubscribedApp::List.call(client: Whatsapp::Client.new(waba_id: "OTHER_WABA_ID"))
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api>
