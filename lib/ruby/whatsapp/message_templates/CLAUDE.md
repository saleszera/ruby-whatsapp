# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This directory manages the message templates on a WhatsApp Business Account — create,
list, read, edit, delete. It is the **opposite side** of `messages/template.rb`, which
sends an already-approved template.

Read the next section before changing anything here. Almost every mistake in this
module comes from conflating the two.

## The one thing to internalise: these are two different APIs

"Template" means two unrelated payload schemas depending on direction:

| | **Management** (this directory) | **Sending** (`../messages/template.rb`) |
|---|---|---|
| Endpoint | `/{WABA_ID}/message_templates` | `/{PHONE_ID}/messages` |
| ID | `client.waba_id` | `client.phone_id` |
| Permission | `whatsapp_business_management` | `whatsapp_business_messaging` |
| Defines | the template *shape*, with placeholders | the *values* for those placeholders |
| Component key | `text` + `example` | `parameters` |
| Component types | `HEADER`, `BODY`, `FOOTER`, `BUTTONS` (uppercase, plural) | `header`, `body`, `button` (lowercase, singular) |
| Buttons | one `BUTTONS` component holding N buttons | N `button` components, each with `sub_type` + `index` |

The same template, both sides:

```jsonc
// MANAGEMENT: define the placeholder and give Meta a sample value for review
{ "type": "BODY",
  "text": "Thank you, {{1}}! Your order number is {{2}}.",
  "example": { "body_text": [["Pablo", "860198-230332"]] } }

// SENDING: supply real values. No text. No example.
{ "type": "body",
  "parameters": [{ "type": "text", "text": "Pablo" },
                 { "type": "text", "text": "860198-230332" }] }
```

**`Messages::Template::Component` and `::Parameter` are therefore not reusable here**,
and vice versa. The only genuinely shared thing is `Utils::LanguageCodes`. Do not try
to unify them; one class cannot serialize two incompatible shapes without becoming a
conditional mess.

Full API research, including everything deliberately left unimplemented, is in
[`docs/template-management-api.md`](../../../../docs/template-management-api.md).

## Architecture

Three layers, each with one job:

```
MessageTemplates                 transport: paths, requests, hands bodies to Response
  ├── Template                   create + upsert payload (identity: name/language/category)
  ├── LibraryTemplate            create-from-library payload (no components at all)
  │     ├── BodyInputs
  │     └── ButtonInputs
  ├── ComponentSet               the components + every rule that SPANS components
  │     └── Component            registry → one class per component type
  │           ├── Header, Body, Footer, Buttons
  │           ├── LimitedTimeOffer
  │           └── Carousel → Carousel::Card
  │                 └── Button   registry → one class per button type
  │                       ├── QuickReply, Url, PhoneNumber, CopyCode
  │                       └── Otp → Otp::SupportedApp
  └── Response                   four different response shapes
        ├── Created              {id, status, category}
        ├── Node                 the full template object
        └── Collection           {data, paging, summary} → Paging, Summary, QualityScore

shared:  ValueObject  ParameterFormats  Categories  Statuses  Placeholders  Example
```

### The validation split (important)

**A component validates itself. `ComponentSet` validates how components relate.**

So `Body` owns its own 1024-character limit, but "a `FOOTER` is forbidden when a
`LIMITED_TIME_OFFER` is present" lives on `ComponentSet` — it is the only object that
can see the siblings. Without this line, cross-component rules get copy-pasted across
classes that each only see half the picture.

`ComponentSet` is a separate object from `Template` (rather than logic inside it)
because **editing** a template replaces its components wholesale without re-supplying a
name or language. `MessageTemplates#update` needs exactly the component rules and none
of the identity ones. Its `category:` is optional for the same reason: when absent, the
category-dependent rules are skipped rather than guessed at.

## Conventions

Same as `../messages/CLAUDE.md` unless noted:

1. **Include `ValueObject`**, not `ActiveModel::Validations` directly. It brings the
   validations, the class-level `.serialize(**)` shorthand, `blank_value?` and
   `reject_unsupported`.
2. **Own your wire type as `Defaults::TYPE`.** The `Component::TYPES` and
   `Button::TYPES` registries map kind → class only; the uppercase API string lives on
   the class, so there is one source of truth for both serialization and the cap checks
   that count types.
3. **Resolve through a frozen registry, never `const_get` on caller input.** Mirrors
   `Messages::KINDS` and `Interactive::ACTION_TYPES`.
4. **Accept either enum casing, emit uppercase.** Meta's docs are internally
   inconsistent (the components reference uses `"HEADER"`, the carousel and
   limited-time-offer pages use `"header"`), and responses come back uppercase. Every
   enum module has a `.normalize` for this.
5. **Call `super(**)` then `validate!`** in component `initialize`, so `Base` can set
   `parameter_format` first.
6. **Never let a nested helper raise a non-validation error out of `initialize`.** See
   "Deliberate decisions" below.

### `blank_value?`, not `blank?`

`ValueObject#blank_value?` is deliberately not named `blank?`. ActiveModel's presence
validator calls `value.blank?` on attribute values, so a one-argument `blank?` here
shadows `Object#blank?` on every component and makes `validates :header, presence: true`
raise `NoMethodError` instead of validating. This cost real debugging time; do not
"tidy" the name.

## Deliberate decisions

Each of these looks like an oversight and is not.

**`Response::Node#components` stays raw hashes.** It is not rebuilt into the
`Component` classes. Those validate a payload being *written*; this is Meta's echo of
one, carrying fields the write side does not model. Running write-side rules over data
we did not author would raise on perfectly valid responses. Read it as data; build a new
`Template` to change something.

**`Example` raises `ArgumentError`, components convert it to a validation error.**
`Component::Base#build_example_payload` rescues it into `@example_error`, which
`validate_example_shape` reports. `Example` stays strict for direct use, while callers
of `Header`/`Body` get one error type for one kind of mistake instead of two.

**The Markdown check ignores placeholder contents.** `Header#validate_no_markdown`
strips `{{...}}` before scanning. Named placeholders are lowercase-and-underscores by
definition, so scanning raw text would reject `{{sale_start_date}}` for its underscore
and make named parameters unusable in a text header.

**No class-level convenience methods** (`MessageTemplates.create(...)`). `Media`, the
closest analog, is instance-only. `Messages` has generated `send_<kind>!` methods only
because it has a *kind registry* to generate them from; a fixed set of CRUD verbs does
not.

**Per-type button caps only where documented.** `Buttons::MAX_PER_TYPE` covers
`QUICK_REPLY` (10), `URL` (2), `PHONE_NUMBER` (1), `COPY_CODE` (1). `OTP` is uncapped
because Meta states no limit for it — inventing one would reject valid payloads.

**Carousel cards allow 0–2 buttons.** Meta says "up to 2" and never states a minimum,
so none is enforced.

**`update` accepts `parameter_format:` but never sends it.** It is needed to build and
validate replacement components locally; Meta does not list it among the editable
fields.

## Reference

Every example below was run through the real classes (`bundle exec ruby -Ilib`) and its
output checked against the verbatim JSON in Meta's docs. The payloads shown are exact.

### Entry point

```ruby
templates = Whatsapp::MessageTemplates.new           # or .new(client: my_client)
```

Requires `waba_id` — set it via `Whatsapp.configure` or `Client.new(waba_id:)`.
Omitting it raises `TemplateError` before any request is made.

| Method | Request | Returns |
|---|---|---|
| `create(**attrs)` | `POST /{waba_id}/message_templates` | `Response::Created` |
| `create_from_library(**attrs)` | same edge, library payload | `Response::Created` |
| `upsert(**attrs)` | `POST /{waba_id}/upsert_message_templates` | `Response::Created` |
| `list(**filters)` | `GET /{waba_id}/message_templates` | `Response::Collection` |
| `find(template_id:, fields:)` | `GET /{template_id}` | `Response::Node` |
| `update(template_id:, **attrs)` | `POST /{template_id}` | `Boolean` |
| `delete(name:/hsm_id:/hsm_ids:)` | `DELETE /{waba_id}/message_templates` | `Boolean` |

`update` is a **POST to the template's own ID** — `PUT`/`PATCH` are unsupported on this
edge.

### Template anatomy

- `name` — `^[a-z0-9_]+$`, max 512. Not unique: one per `(name, language)` pair.
- `language` **XOR** `languages` — singular for `create`, the array for `upsert`.
- `category` — `AUTHENTICATION` | `MARKETING` | `UTILITY`.
- `parameter_format` — `POSITIONAL` (default) | `NAMED`.
- Optional: `sub_category`, `message_send_ttl_seconds`, `allow_category_change`
  (a no-op since 2025-04-09), `cta_url_link_tracking_opted_out`.

### Parameter formats and the `example` trap

The `example` key **name** changes with both the component and the format. `Example`
owns this; it is the single most rejection-prone detail in the API.

| role | `POSITIONAL` | `NAMED` |
|---|---|---|
| header | `header_text: ["Sale"]` (flat) | `header_text_named_params: [{param_name:, example:}]` |
| body | `body_text: [["a","b"]]` (**nested**) | `body_text_named_params: [{param_name:, example:}]` |

Pass whichever input shape suits you — an `Array` (positional), a `Hash` of
name ⇒ example (named), Meta's own `[{param_name:, example:}]`, or a fully-built payload
hash copied straight out of the docs.

> **Ruby gotcha:** Meta's own examples include text like `Your order #{{2}}`. In a
> double-quoted Ruby string `#{` starts interpolation — use single quotes or escape it.

### Components

| Component | Key rules |
|---|---|
| `Header` | Max 1. `format`: `TEXT` (text ≤ 60, **at most one** placeholder, no Markdown) / `IMAGE` `VIDEO` `DOCUMENT` `GIF` (needs `header_handle`, no text) / `LOCATION` (nothing else; coordinates supplied when sending) |
| `Body` | **Required, exactly one.** `text` ≤ 1024 with any number of placeholders and a matching `example`, **XOR** `add_security_recommendation` for authentication templates |
| `Footer` | Max 1. `text` ≤ 60 and **no placeholders**, **XOR** `code_expiration_minutes` (1–90) |
| `Buttons` | Max 1 component, 1–10 buttons. Quick-replies must be **contiguous**. Per-type caps above |
| `LimitedTimeOffer` | `text` ≤ 16, optional `has_expiration`. MARKETING only |
| `Carousel` | 2–10 cards, **all structurally identical**. MARKETING only |
| `Carousel::Card` | Media header (`IMAGE`/`VIDEO`) required, optional body, ≤ 2 buttons. No `card_index` — that is send-side only |

### Buttons

| Button | Fields |
|---|---|
| `QuickReply` | `text` ≤ 25 |
| `Url` | `text` ≤ 25, `url` ≤ 2000, at most one variable and it must be **at the end**, `example` required when it has one (a **flat array on the button**, unlike header/body) |

> The URL variable is counted by **occurrence** (`Placeholders.occurrences`), not by unique
> name, so `.../{{1}}/details/{{1}}` is rejected: it ends in a placeholder and names one
> parameter, but the leading one still sits mid-URL. Everywhere else — body examples above
> all — the unique count (`Placeholders.count`) is the correct one, since Meta treats a
> repeated `{{1}}` as a single parameter needing a single example.
| `PhoneNumber` | `text` ≤ 25, `phone_number` ≤ 20 |
| `CopyCode` | `example` ≤ 20 (a **bare string**), **no `text`** — Meta supplies the label |
| `Otp` | `otp_type`: `COPY_CODE`/`ONE_TAP`/`ZERO_TAP`/`NO_BUTTONS`. `supported_apps` required for one/zero-tap, `zero_tap_terms_accepted` must be true for zero-tap. `text`/`autofill_text` rejected — Meta localises them |

### Cross-component rules (`ComponentSet`)

- exactly one `BODY`; at most one each of `HEADER`/`FOOTER`/`BUTTONS`/`CAROUSEL`/`LIMITED_TIME_OFFER`
- `CAROUSEL` or `LIMITED_TIME_OFFER` → category must be `MARKETING`
- `LOCATION` header → category must be `UTILITY` or `MARKETING`
- `LIMITED_TIME_OFFER` present → `FOOTER` **forbidden**, `BODY` ≤ **600**, header
  `IMAGE`/`VIDEO` only, copy-code `example` ≤ **15** and that button must be **first**

### Verified examples

**Standard utility template, positional:**

```ruby
Whatsapp::MessageTemplates.new.create(
  name: "order_confirmation", language: "en_US", category: "utility",
  components: [
    { type: :header, format: "DOCUMENT", header_handle: "4::YX" },
    { type: :body,
      text: "Thank you for your order, {{1}}! Your order number is {{2}}.",
      example: ["Pablo", "860198-230332"] },
    { type: :buttons, buttons: [
      { type: :phone_number, text: "Call", phone_number: "15550051310" },
      { type: :url, text: "Contact Support", url: "https://www.luckyshrub.com/support" },
    ] },
  ]
)
# payload => {
#   name: "order_confirmation", language: "en_US", category: "UTILITY",
#   parameter_format: "POSITIONAL",
#   components: [
#     { type: "HEADER", format: "DOCUMENT", example: { header_handle: ["4::YX"] } },
#     { type: "BODY", text: "Thank you for your order, {{1}}! Your order number is {{2}}.",
#       example: { body_text: [["Pablo", "860198-230332"]] } },
#     { type: "BUTTONS", buttons: [
#       { type: "PHONE_NUMBER", text: "Call", phone_number: "15550051310" },
#       { type: "URL", text: "Contact Support", url: "https://www.luckyshrub.com/support" }] },
#   ] }
```

**Named parameters:**

```ruby
Whatsapp::MessageTemplates::Template.new(
  name: "order_confirmation", language: "en_US", category: "utility", parameter_format: "named",
  components: [
    { type: :body,
      text: "Thank you, {{first_name}}! Your order number is {{order_number}}.",
      example: { first_name: "Pablo", order_number: "860198-230332" } },
  ]
).serialize
# => { ..., parameter_format: "NAMED", components: [{ type: "BODY", text: "...",
#      example: { body_text_named_params: [
#        { param_name: "first_name", example: "Pablo" },
#        { param_name: "order_number", example: "860198-230332" }] } }] }
```

**Authentication template (note `languages:` and the flag-based components):**

```ruby
Whatsapp::MessageTemplates.new.upsert(
  name: "authentication_code_autofill_button", languages: %w[en_US es_ES fr],
  category: "AUTHENTICATION",
  components: [
    { type: :body, add_security_recommendation: true },
    { type: :footer, code_expiration_minutes: 15 },
    { type: :buttons, buttons: [
      { type: :otp, otp_type: "ONE_TAP",
        supported_apps: [{ package_name: "com.example.luckyshrub", signature_hash: "K8a/AINcGX7" }] },
    ] },
  ]
)
# components => [{ type: "BODY", add_security_recommendation: true },
#                { type: "FOOTER", code_expiration_minutes: 15 },
#                { type: "BUTTONS", buttons: [{ type: "OTP", otp_type: "ONE_TAP",
#                  supported_apps: [{ package_name: "...", signature_hash: "..." }] }] }]
```

**Limited-time offer:**

```ruby
Whatsapp::MessageTemplates::Template.new(
  name: "limited_time_offer_caribbean_pkg_2023", language: "en_US", category: "marketing",
  components: [
    { type: :header, format: "image", header_handle: "4::aW" },
    { type: :limited_time_offer, text: "Expiring offer!", has_expiration: true },
    { type: :body, text: "Good news, {{1}}! Use code {{2}} to get 25% off!",
      example: ["Pablo", "CARIBE25"] },
    { type: :buttons, buttons: [
      { type: :copy_code, example: "CARIBE25" },
      { type: :url, text: "Book now!", url: "https://x.test/offers?code={{1}}", example: "n3mtql" },
    ] },
  ]
).serialize
# => { ..., components: [..., { type: "LIMITED_TIME_OFFER",
#      limited_time_offer: { text: "Expiring offer!", has_expiration: true } }, ...] }
```

**Carousel** (cards must be structurally identical; each serializes to `{components: [...]}`
with no `card_index`):

```ruby
card = {
  header: { format: "image", header_handle: "4::aW" },
  body: { text: "Rare {{1}} in stock!", example: ["Tulips"] },
  buttons: [{ type: :quick_reply, text: "More like this" }],
}
Whatsapp::MessageTemplates::Template.new(
  name: "summer_carousel", language: "en_US", category: "marketing",
  components: [
    { type: :body, text: "Summer is here, {{1}}!", example: ["Pablo"] },
    { type: :carousel, cards: [card, card] },
  ]
).serialize
```

**Library clone** (no components; usually comes back `APPROVED` immediately):

```ruby
Whatsapp::MessageTemplates.new.create_from_library(
  name: "my_delivery_update", language: "en_US", category: "UTILITY",
  library_template_name: "delivery_update_1",
  library_template_button_inputs: [
    { type: "URL", url: { base_url: "https://www.example.com/{{1}}",
                          url_suffix_example: "https://www.example.com/order_update" } },
  ]
)
```

**Reading and paging:**

```ruby
page = templates.list(status: %w[APPROVED], fields: %w[name category status], limit: 25)
page.select(&:approved?).map(&:name)   # Collection is Enumerable
page.remaining                         # headroom against the per-WABA cap
templates.list(after: page.next_cursor) if page.next_cursor
```

**Editing** (components are a full replacement):

```ruby
templates.update(template_id: "564750795574598", category: "MARKETING")            # => true
templates.update(template_id: "564750795574598", components: [...])                # => true
```

Only `APPROVED`/`REJECTED`/`PAUSED` templates are editable (`Node#editable?`), and
approved ones allow 10 edits per 30 days and 1 per 24 hours. Neither rate limit is
checkable locally — they surface as API errors.

**Deleting** (three mutually exclusive modes):

```ruby
templates.delete(name: "order_confirmation")                    # ALL language variants
templates.delete(hsm_id: "1407680676729941", name: "order_confirmation")
templates.delete(hsm_ids: %w[1387372356726668 1304694804498707])  # ≤ 100, not with the others
```

Deleting an approved template blocks reuse of its name for 30 days. `DISABLED`
templates cannot be deleted at all.

### Lifecycle

Only `APPROVED` templates can be sent. Review is asynchronous and can take 24 hours;
the outcome arrives via webhook, already modelled elsewhere in this gem — polling
`#find` is the fallback, not the intended path:

| Webhook field | Class |
|---|---|
| `message_template_status_update` | `Webhook::MessageTemplateStatusUpdate` |
| `message_template_quality_update` | `Webhook::MessageTemplateQualityUpdate` |
| `message_template_components_update` | `Webhook::MessageTemplateComponentsUpdate` |
| `template_category_update` | `Webhook::TemplateCategoryUpdate` |

## Not implemented

Deliberate, per the confidence tiers in `docs/template-management-api.md`:

- **Media upload.** Media headers take a `header_handle` the caller already has. The
  Resumable Upload API that produces one needs an `app_id` (absent from
  `Configuration`) and a second auth scheme (`Authorization: OAuth`, not `Bearer`).
- **Undocumented button types:** `FLOW`, `MPM`, `CATALOG`, `VOICE_CALL`, `VIDEO_CALL`,
  `POSTBACK`, `BOOKING_STATUS`, `PAYMENT_REQUEST`, `REQUEST_CONTACT_INFO`. Named in
  Meta's Graph enum with no published field reference. `LibraryTemplate::ButtonInputs`
  does accept most of them, because Meta documents them by name in *that* context.
- **Undocumented component types:** `GREETING`, `ALBUM`, `CALL_PERMISSION_REQUEST`,
  `TAP_TARGET_CONFIGURATION`, `ATTACHMENT`.
- The `compare` edge, `message_template_previews`, `message_template_library` browse,
  archive/unarchive.
- Marketing Messages API fields: `bid_spec`, `optimization_spec`,
  `degrees_of_freedom_spec`, `product_set_id`.
- Auto-pagination on `#list`.

## Unverified against the live API

Everything here is spec-covered and matches the documented JSON, but four details could
not be settled without a real WABA. Each is isolated to one method so it is a one-line
change:

1. **Enum casing on input.** We emit uppercase; Meta's docs use both. If lowercase turns
   out to be required somewhere, fix the relevant `.normalize`.
2. **`library_template_button_inputs`** — emitted as a real array
   (`LibraryTemplate#serialize`). Meta's guide shows a JSON-*stringified* array while
   the Graph reference types it `array<JSON object>`.
3. **Array list filters** — encoded as JSON arrays
   (`MessageTemplates#encode_filter_value`), consistent with the documented
   `hsm_ids=[...]`. Comma-separated is the other candidate.
4. **`upsert` response shape** — assumed to match create's `{id, status, category}`;
   Meta publishes no example.

## Adding a new component or button type (checklist)

- [ ] Confirm Meta actually publishes a field reference. If not, leave it out and note
      it under "Not implemented" — the webhook module's precedent is to flag confidence,
      not guess schemas.
- [ ] Write the failing spec under `spec/ruby/whatsapp/message_templates/...`
- [ ] Create the class inheriting `Component::Base` or `Button::Base`; include
      `ValueObject` for anything else
- [ ] Define `Defaults::TYPE` with the uppercase wire string
- [ ] Attributes with `# @!attribute` tags, validations, `initialize` calling
      `super(**)` then `validate!`, and `serialize`
- [ ] Doc comment with a `# Source:` link
- [ ] Register it in `Component::TYPES` or `Button::TYPES`
- [ ] Put any rule that involves *another* component in `ComponentSet`, not the new class
- [ ] Add a row and a verified example to this file
- [ ] `bundle exec rake` green before committing
