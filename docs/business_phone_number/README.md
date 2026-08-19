# Registering Business Phone Numbers

A business phone number is unusable with Cloud API until it is **registered**.
Registration is the prerequisite that makes sending, media, and templates work for that
number at all — not an optional extra.

`Whatsapp::BusinessPhoneNumber` wraps all four endpoints in that path:

```
RequestCode  ->  VerifyCode  ->  Register            (onboarding)
(send OTP)       (confirm it)    (activate on Cloud API)

Deregister                                            (the reverse switch)
```

Addresses your **phone number** (`phone_id`, not `waba_id`), like
[messages](../messages/README.md) and [media](../media/README.md), and needs both the
`whatsapp_business_messaging` and `whatsapp_business_management` permissions.

> **Looking for the account itself?** [`Account::Get` / `Account::Update`](account.md)
> read and update the WhatsApp Business Account a number belongs to — its name,
> timezone, review and verification status. Those are the one `waba_id`-scoped corner
> of this module.

> **Unrelated to [`SubscribedApp`](../subscribed_app/README.md).** That turns *webhook
> delivery* on and off for a whole WhatsApp Business Account. This is per phone number
> and has nothing to do with notifications.

## The whole flow

```ruby
Whatsapp.configure do |config|
  config.api_key  = ENV.fetch("WHATSAPP_API_KEY")
  config.phone_id = ENV.fetch("WHATSAPP_PHONE_ID")
end

Whatsapp::BusinessPhoneNumber::RequestCode.call(code_method: "SMS", language: "en_US")
Whatsapp::BusinessPhoneNumber::VerifyCode.call(code: "123456")
Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834")
Whatsapp::BusinessPhoneNumber::Deregister.call
```

| Method | Request | Returns |
| --- | --- | --- |
| `RequestCode.call(code_method:, language:)` | `POST /{phone_id}/request_code` | `Response` |
| `VerifyCode.call(code:)` | `POST /{phone_id}/verify_code` | `Response` (may carry `id`) |
| `Register.call(pin:, data_localization_region:)` | `POST /{phone_id}/register` | `Response` |
| `Deregister.call` | `POST /{phone_id}/deregister` | `Response` |
| [`Account::Get.call(fields:)`](account.md) | `GET /{waba_id}` | `Account::Details` |
| [`Account::Update.call(name:, timezone_id:)`](account.md) | `POST /{waba_id}` | `Response` |

Every action accepts an optional `client:` and raises
`Whatsapp::BusinessPhoneNumber::Error` if `phone_id` is missing or the API rejects the
request.

## Requesting a verification code

Sends a one-time code to the number, by SMS or automated voice call.

```ruby
Whatsapp::BusinessPhoneNumber::RequestCode.call(code_method: "SMS", language: "en_US").success
# => true
```

| Field | Required | Rules |
| --- | --- | --- |
| `code_method` | yes | `"SMS"` or `"VOICE"` — either casing accepted, emitted uppercase |
| `language` | yes | The locale for the message, e.g. `"en_US"`. Presence only |

> `language` is deliberately **not** checked against `Utils::LanguageCodes`. That list
> is the set of locales Meta *approves templates* in; this field is closer to a
> delivery preference, and Meta documents it as a plain string with no enum.

```ruby
Whatsapp::BusinessPhoneNumber::RequestCode.call(code_method: "CARRIER_PIGEON", language: "en_US")
# => ActiveModel::ValidationError: Code method is not included in the list
```

Both fields are always sent — neither is compacted away:

```ruby
Whatsapp::BusinessPhoneNumber::RequestCode.new(code_method: "sms", language: "en_US").serialize
# => { code_method: "SMS", language: "en_US" }
```

## Verifying the code

```ruby
result = Whatsapp::BusinessPhoneNumber::VerifyCode.call(code: "123456")

result.success   # => true
result.id        # => "106540352242922"  — the phone number ID, when Meta returns one
```

`code` is checked for presence only — Meta documents no format, so a wrong-but-present
code is rejected server-side.

The OTP is redacted from `#inspect`:

```ruby
Whatsapp::BusinessPhoneNumber::VerifyCode.new(code: "123456").inspect
# => "#<Whatsapp::BusinessPhoneNumber::VerifyCode code=[REDACTED]>"
```

## Registering

The step that actually activates the number on Cloud API.

```ruby
Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834").success
# => true
```

| Field | Required | Rules |
| --- | --- | --- |
| `pin` | yes | Exactly **6 digits** — the existing two-step verification PIN, or the one to set |
| `data_localization_region` | no | One of 14 region codes |

```ruby
Whatsapp::BusinessPhoneNumber::Register.call(pin: "1234")
# => ActiveModel::ValidationError: Pin must be exactly 6 digits
```

### Data localization

Passing a region enables local storage — message data at rest stays in that region:

```ruby
Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834", data_localization_region: "CH")
```

| Region | Codes |
| --- | --- |
| APAC | `AU` `ID` `IN` `JP` `SG` `KR` |
| Europe | `DE` `CH` `GB` |
| LATAM | `BR` |
| MEA | `BH` `ZA` `AE` |
| NORAM | `CA` |

Omitted when not given:

```ruby
Whatsapp::BusinessPhoneNumber::Register.new(pin: "212834").serialize
# => { messaging_product: "whatsapp", pin: "212834" }

Whatsapp::BusinessPhoneNumber::Register.new(pin: "212834", data_localization_region: "ch").serialize
# => { messaging_product: "whatsapp", pin: "212834", data_localization_region: "CH" }
```

The PIN is redacted from `#inspect`, and no validation error message ever echoes it:

```ruby
Whatsapp::BusinessPhoneNumber::Register.new(pin: "212834", data_localization_region: "CH").inspect
# => "#<Whatsapp::BusinessPhoneNumber::Register pin=[REDACTED] data_localization_region=\"CH\">"
```

## Deregistering

```ruby
Whatsapp::BusinessPhoneNumber::Deregister.call.success   # => true
```

Deregistering makes the number unusable with Cloud API and disables local storage. It
does **not** delete the number or its message history. A number in use with both Cloud
API and the WhatsApp Business app cannot be deregistered.

`Deregister` takes no arguments and has nothing to validate — its payload is `{}`.

## Targeting a different number

Inject a client rather than mutating global configuration:

```ruby
Whatsapp::BusinessPhoneNumber::Register.call(
  pin: "212834",
  client: Whatsapp::Client.new(phone_id: "OTHER_PHONE_ID")
)
```

## Rate limits

> **`Register` / `Deregister`:** 10 requests per business number in a **72-hour moving
> window**. Exceeding it returns error `133016` and blocks the operation for the next
> 72 hours.
>
> **`RequestCode` / `VerifyCode`:** "standard Graph API rate limits", plus possible
> additional throttling — Meta publishes no number.

This is server-side state the gem cannot observe, so there is no client-side tracking.
It is also why every action validates locally first: a rejected attempt still counts
against the limit.

## Errors

```ruby
Whatsapp::BusinessPhoneNumber::Register.call(pin: "212834")
# => Whatsapp::BusinessPhoneNumber::Error: phone_id is required for the register edge;
#    set it via Whatsapp.configure or Client.new(phone_id:)

# non-2xx response
# => Whatsapp::BusinessPhoneNumber::Error: Failed to register business phone number:
#    400 Bad Request - {"error":{"message":"..."}}
```

Local validation failures raise `ActiveModel::ValidationError` before any request. See
[../errors.md](../errors.md).

## Not wrapped

- **Client-side rate-limit tracking** — server-side state the gem cannot observe.
- **Two-step verification PIN management.** `Register` *consumes* an existing PIN;
  setting or changing one is a different endpoint.

---

**See also:** [Reading and updating the business account](account.md)

---

**Meta docs:**
[registration](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration)
· [request code](https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-verification-request-code-api)
· [verify code](https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/verify-code-api)
· [deregister](https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/phone-number-deregister-api)
