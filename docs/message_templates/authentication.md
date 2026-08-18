# Authentication Templates

One-time-password templates invert the usual shape: **Meta supplies and localises the
wording**, so you pass flags rather than text. That's also why they're normally created
for every language at once with `upsert` instead of `create`.

```ruby
templates = Whatsapp::MessageTemplates.new

templates.upsert(
  name: "authentication_code", languages: %w[en_US es_ES fr], category: "AUTHENTICATION",
  components: [
    { type: :body, add_security_recommendation: true },
    { type: :footer, code_expiration_minutes: 15 },
    { type: :buttons, buttons: [{ type: :otp, otp_type: "COPY_CODE" }] },
  ]
)
```

`upsert` requires `languages:` (an array). Passing `language:` raises:

```ruby
templates.upsert(name: "x", language: "en_US", category: "AUTHENTICATION", components: [...])
# => Whatsapp::MessageTemplates::TemplateError: #upsert requires `languages:`
#    (an array of locale codes); use #create for a single one
```

## The flag-based components

| Component | Field | Meaning |
| --- | --- | --- |
| `body` | `add_security_recommendation: true` | Appends Meta's "don't share this code" line |
| `footer` | `code_expiration_minutes: 1..90` | Renders "This code expires in N minutes" |
| `buttons` | one `otp` button | How the user gets the code out of the message |

Body and footer are **XOR** with their text forms — an authentication `body` takes
`add_security_recommendation` *or* `text`, never both:

```ruby
{ type: :body, text: "Your code is {{1}}", add_security_recommendation: true }
# => ActiveModel::ValidationError: Text cannot be combined with add_security_recommendation
```

## OTP button types

| `otp_type` | Behaviour | Extra requirements |
| --- | --- | --- |
| `COPY_CODE` | Shows a "copy code" button | — |
| `ONE_TAP` | Autofills your app on tap | `supported_apps` required |
| `ZERO_TAP` | Autofills with no tap at all | `supported_apps` **and** `zero_tap_terms_accepted: true` |
| `NO_BUTTONS` | Plain text, user copies manually | — |

```ruby
templates.upsert(
  name: "authentication_code_autofill_button", languages: %w[en_US es_ES fr],
  category: "AUTHENTICATION",
  components: [
    { type: :body, add_security_recommendation: true },
    { type: :footer, code_expiration_minutes: 15 },
    { type: :buttons, buttons: [
      { type: :otp, otp_type: "ONE_TAP",
        supported_apps: [{ package_name: "com.example.luckyshrub",
                           signature_hash: "K8a/AINcGX7" }] },
    ] },
  ]
)
# components => [{ type: "BODY", add_security_recommendation: true },
#                { type: "FOOTER", code_expiration_minutes: 15 },
#                { type: "BUTTONS", buttons: [{ type: "OTP", otp_type: "ONE_TAP",
#                  supported_apps: [{ package_name: "...", signature_hash: "..." }] }] }]
```

> **`text` and `autofill_text` are rejected** on an OTP button — Meta localises those
> labels itself:
>
> ```ruby
> { type: :otp, otp_type: "COPY_CODE", text: "Copy it" }
> # => ActiveModel::ValidationError: Text cannot be set on an OTP button;
> #    Meta localises the label
> ```

## Validation errors

```ruby
{ type: :otp, otp_type: "ONE_TAP" }
# => ActiveModel::ValidationError: Supported apps can't be blank for the ONE_TAP OTP type

{ type: :otp, otp_type: "ZERO_TAP", supported_apps: [...] }
# => ActiveModel::ValidationError: Zero tap terms accepted must be accepted
#    for the ZERO_TAP OTP type

{ type: :footer, code_expiration_minutes: 120 }
# => ActiveModel::ValidationError: Code expiration minutes must be in 1..90
```

Note that unlike other categories, `OTP` buttons are **not** capped per type — Meta
publishes no limit, so the gem invents none.

## Sending one

Once approved, an authentication template is sent like any other — see
[../messages/template.md](../messages/template.md). The code itself goes in the body
parameter, and (for `COPY_CODE`/`ONE_TAP`) also as the button's `payload`.

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/authentication-templates/authentication-templates>
