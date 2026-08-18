# Carousel Templates

Two to ten swipeable cards under a shared body message — a product row, a set of
listings, a group of offers.

> **MARKETING only.** A carousel on a `UTILITY` or `AUTHENTICATION` template is
> rejected locally:
>
> ```ruby
> # => ActiveModel::ValidationError: Components CAROUSEL is only supported on
> #    MARKETING templates, not UTILITY
> ```

```ruby
card = {
  header: { format: "IMAGE", header_handle: "4::aW..." },
  body: { text: "Rare {{1}} in stock!", example: ["Tulips"] },
  buttons: [{ type: :quick_reply, text: "More like this" }],
}

Whatsapp::MessageTemplates.new.create(
  name: "summer_carousel", language: "en_US", category: "MARKETING",
  components: [
    { type: :body, text: "Summer is here, {{1}}!", example: ["Pablo"] },
    { type: :carousel, cards: [card, card] },
  ]
)
```

The template still needs its own top-level `BODY` — the carousel sits *below* it.

## Card structure

| Field | Required | Rules |
| --- | --- | --- |
| `header` | yes | `format` must be `IMAGE` or `VIDEO` |
| `body` | no | Same rules as a normal body |
| `buttons` | no | **0–2** buttons per card |

> **All cards must be structurally identical.** Same header format, same button types
> in the same order, and body text on either every card or none. The gem computes a
> signature per card and compares them:
>
> ```ruby
> # => ActiveModel::ValidationError: Cards must all have an identical structure:
> #    same header format, same button types, and body text on either every card or none
> ```

Meta says "up to 2" buttons and never states a minimum, so **zero buttons is valid**.

## Serialized payload

Each card serializes to a bare `{components: [...]}` — note there is **no
`card_index`** here. That is send-side only:

```ruby
Whatsapp::MessageTemplates::Template.new(
  name: "summer_carousel", language: "en_US", category: "marketing",
  components: [
    { type: :body, text: "Summer is here, {{1}}!", example: ["Pablo"] },
    { type: :carousel, cards: [card, card] },
  ]
).serialize
# => {
#   name: "summer_carousel", language: "en_US", category: "MARKETING",
#   parameter_format: "POSITIONAL",
#   components: [
#     { type: "BODY", text: "Summer is here, {{1}}!", example: { body_text: [["Pablo"]] } },
#     { type: "CAROUSEL", cards: [
#       { components: [
#         { type: "HEADER", format: "IMAGE", example: { header_handle: ["4::aW..."] } },
#         { type: "BODY", text: "Rare {{1}} in stock!", example: { body_text: [["Tulips"]] } },
#         { type: "BUTTONS", buttons: [{ type: "QUICK_REPLY", text: "More like this" }] },
#       ] },
#       { components: [...] },
#     ] },
#   ]
# }
```

## Media handles

`header_handle` is **not** a media ID from [`Media#upload`](../media/README.md). It
comes from Meta's Resumable Upload API, which this gem does not wrap — see
[README.md § Not wrapped](README.md#not-wrapped).

## Validation errors

```ruby
{ type: :carousel, cards: [card] }
# => ActiveModel::ValidationError: Cards is too short (minimum is 2 characters)

{ type: :carousel, cards: [card_with_image_header, card_with_video_header] }
# => ActiveModel::ValidationError: Cards must all have an identical structure: ...

{ header: { format: "TEXT", text: "Hi" }, body: ..., buttons: [...] }
# => ActiveModel::ValidationError: Header format must be IMAGE or VIDEO
#    for a carousel card, got TEXT
```

---

**Meta docs:** <https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/carousel-templates>
