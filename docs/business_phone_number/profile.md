# Reading and Updating the Business Profile

A business phone number has a **business profile** — the public card a WhatsApp user sees
before they reply: the about line, the description, where the business is, how else to reach
it, and what industry it is in. The rest of this module drives whether a number *works*;
`Whatsapp::BusinessPhoneNumber::Profile` decides how it *looks*.

> **Same `phone_id` as the onboarding actions.** Meta exposes the profile as an edge on the
> phone number itself, so `Profile` addresses `phone_id` exactly like
> [`RequestCode`/`VerifyCode`/`Register`/`Deregister`](README.md) — unlike
> [`Account`](account.md), which is this module's one `waba_id`-scoped corner.

```ruby
Whatsapp.configure do |config|
  config.api_key  = ENV.fetch("WHATSAPP_API_KEY")
  config.phone_id = ENV.fetch("WHATSAPP_PHONE_ID")
end

Whatsapp::BusinessPhoneNumber::Profile::Get.call.about                    # => "Open daily 9-5"
Whatsapp::BusinessPhoneNumber::Profile::Update.call(about: "Open 9-6")    # => #<Response success=true>
```

| Method | Request | Returns |
| --- | --- | --- |
| `Get.call(client:, fields:)` | `GET /{phone_id}/whatsapp_business_profile` | `Profile::Details` |
| `Update.call(client:, **fields)` | `POST /{phone_id}/whatsapp_business_profile` | `BusinessPhoneNumber::Response` |

Two independent actions, so two classes — the same shape as [`Account`](account.md) and
[subscribed apps](../subscribed_app/README.md), not the single-object CRUD of
[templates](../message_templates/README.md).

## Reading the profile

```ruby
profile = Whatsapp::BusinessPhoneNumber::Profile::Get.call

profile.about        # => "Open daily 9-5"
profile.vertical     # => "RETAIL"
profile.websites     # => ["https://acme.test"]
```

Ask for specific fields with `fields:` — an Array or a String, comma-joined for you:

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Get.call(fields: %w[about vertical websites])
Whatsapp::BusinessPhoneNumber::Profile::Get.call(fields: "about,vertical,websites")
```

`Fields::ALL` requests everything Meta publishes, without hand-typing the list:

```ruby
profile = Whatsapp::BusinessPhoneNumber::Profile::Get.call(
  fields: Whatsapp::BusinessPhoneNumber::Profile::Get::Fields::ALL
)
```

| Field | Description |
| --- | --- |
| `messaging_product` | The messaging service — always `"whatsapp"` in practice |
| `about` | The text shown in the profile's About section |
| `address` | The business's physical address |
| `description` | The business description |
| `email` | The business's contact email address |
| `profile_picture_url` | URL of the current profile picture |
| `websites` | The business's website URLs |
| `vertical` | One of `Profile::Verticals::ALL` |

> `fields` is **not** validated against `Fields::ALL`. Those constants are for
> convenience, not enforcement — a field Meta adds later works without a gem release.
> Only what Meta documents as a *client-side* rule is checked locally.

Meta wraps the read in a `data` array; `Profile::Details` unwraps it for you, so there is no
`.data.first` to reach through. Every field is optional in the response, so anything you did
not request is `nil` rather than an error.

> Read-side values are never validated or normalized on the way in. A `vertical` Meta adds
> later still round-trips untouched, so `profile.vertical` is always exactly what the API
> sent — compare it against `Verticals::ALL` rather than expecting `Details` to have
> rejected it. Same reasoning as [`Account::Details`](account.md#status-values)' statuses and
> [`MessageTemplates::Response::Node#components`](../message_templates/responses.md).

## Updating the profile

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Update.call(
  about: "Open daily 9-6", vertical: "RETAIL", websites: ["https://acme.test"]
).success
# => true
```

| Field | Required | Rules |
| --- | --- | --- |
| `about` | no | At most **139** characters |
| `address` | no | At most **256** characters |
| `description` | no | At most **512** characters |
| `email` | no | At most **128** characters. Format is *not* checked — see below |
| `vertical` | no | One of `Verticals::ALL` — either casing accepted, emitted uppercase |
| `websites` | no | At most **2** URLs |
| `profile_picture_handle` | no | Non-empty when given. From the Resumable Upload API |

Every field is optional, but **at least one must be present** — otherwise the request would
spend a call to change nothing:

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Update.call
# => ActiveModel::ValidationError: at least one of about, address, description, email,
#    vertical, websites, profile_picture_handle must be provided
```

The limits and the vertical enum are checked before anything is sent:

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Update.call(about: "a" * 140)
# => ActiveModel::ValidationError: About is too long (maximum is 139 characters)

Whatsapp::BusinessPhoneNumber::Profile::Update.call(vertical: "SPACESHIPS")
# => ActiveModel::ValidationError: Vertical is not included in the list

Whatsapp::BusinessPhoneNumber::Profile::Update.call(websites: %w[https://a.test https://b.test https://c.test])
# => ActiveModel::ValidationError: websites accepts at most 2 URLs
```

> **`email`'s format is deliberately not validated.** Meta checks the address server-side,
> and a regex here would reject perfectly valid exotic addresses. This gem checks only
> length. Same standing decision as `override_callback_uri` in
> [subscribed apps](../subscribed_app/README.md) — no speculative hardening.

`messaging_product` is always sent for you. An omitted field is compacted out of the body
rather than sent as `null`, which Meta would read as an instruction to blank it:

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Update.new(about: "Open daily").serialize
# => { messaging_product: "whatsapp", about: "Open daily" }

Whatsapp::BusinessPhoneNumber::Profile::Update.new(vertical: "retail").serialize
# => { messaging_product: "whatsapp", vertical: "RETAIL" }
```

### Clearing the website list

An **empty array** is the one falsy-looking value that survives compaction, because that is
how Meta clears the list — and it counts as "changing something", so it satisfies the
at-least-one-field rule on its own:

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Update.new(websites: []).serialize
# => { messaging_product: "whatsapp", websites: [] }
```

### Industry verticals

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Verticals::ALL
```

| Constant | Values |
| --- | --- |
| `Verticals::ALL` | `ALCOHOL` `APPAREL` `AUTO` `BEAUTY` `EDU` `ENTERTAIN` `EVENT_PLAN` `FINANCE` `GOVT` `GROCERY` `HEALTH` `HOTEL` `NONPROFIT` `ONLINE_GAMBLING` `OTC_DRUGS` `OTHER` `PHYSICAL_GAMBLING` `PROF_SERVICES` `RESTAURANT` `RETAIL` `TRAVEL` |

Either casing is accepted and normalized on the way out, so `"retail"`, `:retail`, and
`"RETAIL"` are the same request.

### The profile picture

`profile_picture_handle` is forwarded as an opaque string. The handle itself comes from
Meta's **Resumable Upload API**, which this gem does not wrap:

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Update.call(profile_picture_handle: "4::aW1hZ2UvcG5n...")
```

> **A media ID will not work here.** [`Media#upload`](../media/README.md) returns a media ID
> for *sending* messages — a different thing from an upload handle. Same standing exclusion
> as media handles for [template headers](../message_templates/README.md#not-wrapped).

`Update` returns the same `Whatsapp::BusinessPhoneNumber::Response` as the four onboarding
actions — the endpoint answers with a bare `{ "success": true }`, so there is no separate
response class for it.

## Errors

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Get.call
# => Whatsapp::BusinessPhoneNumber::Error: phone_id is required for the
#    whatsapp_business_profile edge; set it via Whatsapp.configure or Client.new(phone_id:)

# non-2xx response
# => Whatsapp::BusinessPhoneNumber::Error: Failed to update business profile:
#    400 Bad Request - {"error":{"message":"Invalid parameter: email must be a valid ..."}}
```

Both actions raise `Whatsapp::BusinessPhoneNumber::Error` — the same class the onboarding
actions use, so one `rescue` covers the whole module. Local validation failures raise
`ActiveModel::ValidationError` before any request. See [../errors.md](../errors.md).

## Targeting a different number

Inject a client rather than mutating global configuration:

```ruby
Whatsapp::BusinessPhoneNumber::Profile::Get.call(
  client: Whatsapp::Client.new(phone_id: "OTHER_PHONE_ID")
)
```

## Not wrapped

- **The Resumable Upload API** that mints a `profile_picture_handle` — the handle is accepted
  and forwarded, but not produced.
- **Profile read caching.** Meta suggests caching profile reads for moderate periods;
  invalidation is an application concern.

---

**See also:** [Reading and updating the business account](account.md) ·
[Registering business phone numbers](README.md)

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/whatsapp-business-profile-api>
