# Library Templates

Meta maintains a library of pre-written, pre-approved templates for common cases —
delivery updates, appointment reminders, payment confirmations. Cloning one usually
comes back **`APPROVED` immediately**, skipping the 24-hour review entirely.

```ruby
Whatsapp::MessageTemplates.new.create_from_library(
  name: "my_delivery_update", language: "en_US", category: "UTILITY",
  library_template_name: "delivery_update_1",
  library_template_button_inputs: [
    { type: "URL", url: { base_url: "https://example.com/{{1}}",
                          url_suffix_example: "https://example.com/order_update" } },
  ]
)
# => #<Response::Created id="1" status="APPROVED" category="UTILITY">
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `name` | yes | Your name for the clone. `/\A[a-z0-9_]+\z/`, max 512 |
| `language` | yes | Validated against the supported list |
| `category` | yes | `UTILITY` \| `MARKETING` \| `AUTHENTICATION` |
| `library_template_name` | yes | Meta's name for the source template |
| `library_template_body_inputs` | no | Body toggles — see below |
| `library_template_button_inputs` | no | Button configuration — see below |

> **No `components:` at all.** The wording is Meta's; you only supply the identity and
> the few configurable inputs. That is the whole point of the library.

## Body inputs

| Field | Type |
| --- | --- |
| `add_contact_number` | Boolean |
| `add_learn_more_link` | Boolean |
| `add_security_recommendation` | Boolean |
| `add_track_package_link` | Boolean |
| `code_expiration_minutes` | Integer, **1–90** |

```ruby
library_template_body_inputs: {
  add_contact_number: true,
  add_track_package_link: true,
}
```

## Button inputs

`type` is one of `QUICK_REPLY` `URL` `PHONE_NUMBER` `OTP` `MPM` `CATALOG` `FLOW`
`VOICE_CALL` `APP` — deliberately a **wider set** than the button types available to
hand-built templates, because Meta documents these by name in the library context.

| `type` | Required extra |
| --- | --- |
| `URL` | `url: { base_url:, url_suffix_example: }` |
| `PHONE_NUMBER` | `phone_number:` |
| `APP` | `supported_apps:` |
| `OTP` | `otp_type:`, plus `zero_tap_terms_accepted:` for zero-tap |

```ruby
library_template_button_inputs: [
  { type: "URL", url: { base_url: "https://example.com/{{1}}",
                        url_suffix_example: "https://example.com/order_update" } },
  { type: "PHONE_NUMBER", phone_number: "15550051310" },
]
```

## Validation errors

```ruby
{ type: "URL", url: {} }
# => ActiveModel::ValidationError: Url requires a base_url for a URL button input

{ type: "PHONE_NUMBER" }
# => ActiveModel::ValidationError: Phone number can't be blank for a PHONE_NUMBER button input

{ type: "APP" }
# => ActiveModel::ValidationError: Supported apps can't be blank for an APP button input
```

## Unverified detail

`library_template_button_inputs` is emitted as a **real JSON array**. Meta's guide
shows a JSON-*stringified* array while the Graph reference types it
`array<JSON object>`. This has not been settled against a live WABA — if Meta rejects
the array form, it is a one-line change in `LibraryTemplate#serialize`.

## Not wrapped

Browsing the library itself (`message_template_library`) is not wrapped — find the
`library_template_name` you want in WhatsApp Manager or Meta's docs.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/template-library>
