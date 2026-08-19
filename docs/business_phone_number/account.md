# Reading and Updating the Business Account

Every business phone number belongs to a **WhatsApp Business Account** (WABA). The rest
of this module drives a *number's* onboarding; `Whatsapp::BusinessPhoneNumber::Account`
reads and writes the *account* that number sits inside — whether Meta has approved it,
whether the business behind it is verified, who owns it, and what it is called.

> **The one `waba_id` corner of this module.**
> [`RequestCode`/`VerifyCode`/`Register`/`Deregister`](README.md) address your phone
> number (`phone_id`). `Account` addresses the account (`waba_id`), like
> [template management](../message_templates/README.md) and
> [subscribed apps](../subscribed_app/README.md), and needs the
> `whatsapp_business_management` permission.

```ruby
Whatsapp.configure do |config|
  config.api_key = ENV.fetch("WHATSAPP_API_KEY")
  config.waba_id = ENV.fetch("WHATSAPP_WABA_ID")
end

Whatsapp::BusinessPhoneNumber::Account::Get.call.name              # => "Acme Corp"
Whatsapp::BusinessPhoneNumber::Account::Update.call(name: "Acme")  # => #<Response success=true>
```

| Method | Request | Returns |
| --- | --- | --- |
| `Get.call(client:, fields:)` | `GET /{waba_id}` | `Account::Details` |
| `Update.call(client:, name:, timezone_id:)` | `POST /{waba_id}` | `BusinessPhoneNumber::Response` |

Two independent actions, so two classes — the same shape as
[subscribed apps](../subscribed_app/README.md), not the single-object CRUD of
[templates](../message_templates/README.md).

## Reading account details

```ruby
details = Whatsapp::BusinessPhoneNumber::Account::Get.call

details.id     # => "102290129340398"
details.name   # => "Acme Corp"
```

By default Meta returns only `id` and `name`. Ask for more with `fields:` — an Array or
a String, comma-joined for you:

```ruby
Whatsapp::BusinessPhoneNumber::Account::Get.call(fields: %w[id name country])
Whatsapp::BusinessPhoneNumber::Account::Get.call(fields: "id,name,country")
```

`Fields::ALL` requests everything Meta publishes, without hand-typing the list:

```ruby
details = Whatsapp::BusinessPhoneNumber::Account::Get.call(
  fields: Whatsapp::BusinessPhoneNumber::Account::Get::Fields::ALL
)
```

| Field | Description |
| --- | --- |
| `id` | The account's unique identifier |
| `name` | Human-readable account name |
| `timezone_id` | Timezone identifier |
| `message_template_namespace` | Namespace the account's templates live in |
| `account_review_status` | One of `Details::ReviewStatuses::ALL` |
| `business_verification_status` | One of `Details::VerificationStatuses::ALL` |
| `country` | Country code |
| `ownership_type` | One of `Details::OwnershipTypes::ALL` |
| `primary_business_location` | Primary business location |

> `fields` is **not** validated against `Fields::ALL`. Those constants are for
> convenience, not enforcement — a field Meta adds later works without a gem release.
> Only what Meta documents as a *client-side* rule is checked locally.

### Status values

Statuses come back as plain strings, with frozen constants to compare against and three
predicates for the checks you actually make:

```ruby
details.approved?     # => true   — account_review_status == "APPROVED"
details.verified?     # => true   — business_verification_status == "VERIFIED"
details.self_owned?   # => true   — ownership_type == "SELF"
```

| Constant | Values |
| --- | --- |
| `Details::ReviewStatuses::ALL` | `APPROVED` `DEFERRED` `PENDING` `REJECTED` |
| `Details::VerificationStatuses::ALL` | `EXPIRED` `FAILED` `INELIGIBLE` `NOT_VERIFIED` `PENDING` `PENDING_NEED_MORE_INFO` `PENDING_SUBMISSION` `REJECTED` `REVOKED` `VERIFIED` |
| `Details::OwnershipTypes::ALL` | `CLIENT_OWNED` `ON_BEHALF_OF` `SELF` |

> Read-side values are never validated on the way in. A status Meta adds later still
> round-trips untouched, so `details.account_review_status` is always exactly what the
> API sent — same reasoning as
> [`MessageTemplates::Response::Node#components`](../message_templates/responses.md).

Every field is optional in the response, so anything you did not request is `nil`
rather than an error.

## Updating the account

```ruby
Whatsapp::BusinessPhoneNumber::Account::Update.call(name: "Acme Corporation").success
# => true
```

| Field | Required | Rules |
| --- | --- | --- |
| `name` | no | Non-empty when given |
| `timezone_id` | no | Non-empty when given. Meta publishes no enum — presence only |

Both fields are optional, but **at least one must be present** — otherwise the request
would spend a call to change nothing:

```ruby
Whatsapp::BusinessPhoneNumber::Account::Update.call
# => ActiveModel::ValidationError: at least one of name or timezone_id must be provided

Whatsapp::BusinessPhoneNumber::Account::Update.call(name: "")
# => ActiveModel::ValidationError: Name can't be blank
```

An omitted field is compacted out of the body rather than sent as `null`, which Meta
would read as an instruction to blank it:

```ruby
Whatsapp::BusinessPhoneNumber::Account::Update.new(name: "Acme Corp").serialize
# => { name: "Acme Corp" }

Whatsapp::BusinessPhoneNumber::Account::Update.new(name: "Acme Corp", timezone_id: "1").serialize
# => { name: "Acme Corp", timezone_id: "1" }
```

`Update` returns the same `Whatsapp::BusinessPhoneNumber::Response` as the four
onboarding actions — the endpoint answers with a bare `{ "success": true }`, so there is
no separate response class for it.

## Errors

```ruby
Whatsapp::BusinessPhoneNumber::Account::Get.call
# => Whatsapp::BusinessPhoneNumber::Error: waba_id is required for business account
#    details; set it via Whatsapp.configure or Client.new(waba_id:)

# non-2xx response
# => Whatsapp::BusinessPhoneNumber::Error: Failed to get business account details:
#    404 Not Found - {"error":{"message":"WhatsApp Business Account not found",...}}
```

Both actions raise `Whatsapp::BusinessPhoneNumber::Error` — the same class the
onboarding actions use, so one `rescue` covers the whole module. Local validation
failures raise `ActiveModel::ValidationError` before any request. See
[../errors.md](../errors.md).

## Targeting a different account

```ruby
Whatsapp::BusinessPhoneNumber::Account::Get.call(
  client: Whatsapp::Client.new(waba_id: "OTHER_WABA_ID")
)
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/whatsapp-business-account-api>
