# Standard Templates

Utility and marketing templates built from text components — the ordinary case. An
order confirmation, a shipping update, a password-reset notice.

Every standard template needs **exactly one `BODY`**; everything else is optional.

```ruby
templates = Whatsapp::MessageTemplates.new

created = templates.create(
  name: "order_confirmation",           # lowercase alphanumerics and underscores only
  language: "en_US",
  category: "UTILITY",                  # UTILITY | MARKETING | AUTHENTICATION
  components: [
    { type: :header, format: "TEXT", text: "Order {{1}} confirmed", example: ["#1234"] },
    { type: :body,
      text: "Thank you, {{1}}! Your order number is {{2}}.",
      example: ["Pablo", "860198-230332"] },
    { type: :footer, text: "Thanks for shopping with us" },
    { type: :buttons, buttons: [
      { type: :phone_number, text: "Call", phone_number: "15550051310" },
      { type: :url, text: "Track order", url: "https://example.com/orders/{{1}}", example: "1234" },
    ] },
  ]
)

created.id       # => "1259544702043867"
created.status   # => "PENDING" — Meta reviews asynchronously, up to 24 hours
created.pending? # => true
```

## Placeholders and examples

A placeholder is `{{1}}` (positional) or `{{first_name}}` (named). Meta requires a
sample value for every one of them, so a human reviewer can see what the template
actually says. The gem checks the count matches **before** the request:

```ruby
templates.create(
  name: "x", language: "en_US", category: "UTILITY",
  components: [{ type: :body, text: "Hi {{1}} and {{2}}", example: ["Pablo"] }]
)
# => ActiveModel::ValidationError: Example does not match the body text:
#    2 placeholders but 1 example
```

Positional placeholders must **start at `{{1}}` and increment without gaps**, and you
cannot mix the two styles in one template.

> **Ruby gotcha.** Meta's own examples include text like `Your order #{{2}}`. In a
> double-quoted Ruby string, `#{` starts interpolation — use single quotes or escape
> it:
>
> ```ruby
> text: 'Your order #{{2}} has shipped'   # single quotes
> text: "Your order \#{{2}} has shipped"  # or escape
> ```

### Named parameters

Named parameters read better than positional ones for anything non-trivial. Set
`parameter_format: "NAMED"` and pass a Hash of name ⇒ example:

```ruby
templates.create(
  name: "order_confirmation", language: "en_US", category: "UTILITY",
  parameter_format: "NAMED",
  components: [
    { type: :body,
      text: "Thank you, {{first_name}}! Your order number is {{order_number}}.",
      example: { first_name: "Pablo", order_number: "860198-230332" } },
  ]
)
```

### The `example` key trap

The `example` key **name** changes with both the component and the format. This is the
single most rejection-prone detail in the API, so the gem builds it for you — you pass
the values, it picks the key:

| Role | `POSITIONAL` | `NAMED` |
| --- | --- | --- |
| header | `header_text: ["Sale"]` (flat) | `header_text_named_params: [{param_name:, example:}]` |
| body | `body_text: [["a","b"]]` (**nested**) | `body_text_named_params: [{param_name:, example:}]` |

Pass whichever input shape suits you — an `Array` (positional), a `Hash` of
name ⇒ example (named), Meta's own `[{param_name:, example:}]`, or a fully-built
payload hash copied straight out of the docs.

## Serialized payload

```ruby
Whatsapp::MessageTemplates::Template.new(
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
).serialize
# => {
#   name: "order_confirmation", language: "en_US", category: "UTILITY",
#   parameter_format: "POSITIONAL",
#   components: [
#     { type: "HEADER", format: "DOCUMENT", example: { header_handle: ["4::YX"] } },
#     { type: "BODY", text: "Thank you for your order, {{1}}! Your order number is {{2}}.",
#       example: { body_text: [["Pablo", "860198-230332"]] } },
#     { type: "BUTTONS", buttons: [
#       { type: "PHONE_NUMBER", text: "Call", phone_number: "15550051310" },
#       { type: "URL", text: "Contact Support", url: "https://www.luckyshrub.com/support" }] },
#   ]
# }
```

Note the lowercase `category: "utility"` on input and `"UTILITY"` on the wire — every
enum accepts either casing and emits uppercase.

## Rules worth remembering

| Component | Limit |
| --- | --- |
| `header` (TEXT) | ≤ **60** chars, **at most one** placeholder, no Markdown (`*` `_` `~` `` ` ``) |
| `body` | ≤ **1024** chars, any number of placeholders, matching example required |
| `footer` | ≤ **60** chars and **no placeholders** |
| `buttons` | 1–**10** buttons; quick-replies must be **contiguous** |

Full reference in [components.md](components.md).

---

**Meta docs:** <https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/>
