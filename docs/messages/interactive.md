# Interactive Messages

Gives the user tappable UI — buttons, a list, a carousel — instead of asking them to
type a free-text reply. Tapping "Confirm" is one action; typing "yes", "Yes", "yeah",
or "ya" is four things you have to parse.

Unlike every other kind, `Interactive` is a **single class** that dispatches on
`type:` through a frozen registry:

| `type:` | Wire `interactive.type` | Shape |
| --- | --- | --- |
| `:reply_buttons` | `"button"` | [Up to 3 quick-reply buttons](#reply-buttons) |
| `:list_buttons` | `"list"` | [A button expanding into sections of rows](#list) |
| `:url_button` | `"cta_url"` | [A link rendered as a button](#cta-url-button) |
| `:media_carousel` | `"carousel"` | [2–10 swipeable media cards](#media-carousel) |
| `:product_carousel` | `"product_list"` | [2–10 catalog product cards](#product-carousel) |

## Shared fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `type` | yes | One of the five keys above (Symbol or String) |
| `body` | yes | Body text, max **1024** characters |
| `action` | yes | Shape depends on `type` — see each section |
| `header` | no | `{ type: "text"\|"image"\|"video"\|"document", ... }` |
| `footer` | no | `{ text: "..." }`, max **60** characters |

### Header

A text header is capped at **60** characters. Media headers take a **`link:` only** —
there is no media-`id` path on interactive headers, unlike [image](image.md) and
friends:

```ruby
header: { type: "text",  text: "Order #1234" }
header: { type: "image", link: "https://example.com/photo.jpg" }
header: { type: "video", link: "https://example.com/clip.mp4" }
header: { type: "document", link: "https://example.com/invoice.pdf" }
```

A header missing its content raises `Whatsapp::Messages::Interactive::Header::HeaderError`
(not a validation error):

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567", type: :reply_buttons, body: "Pick one",
  header: { type: "image" },
  action: { buttons: [{ id: "a", title: "A" }] }
)
# => Whatsapp::Messages::Interactive::Header::HeaderError: Image link is required for image header
```

---

## Reply buttons

Up to **3** quick-reply buttons. The user's tap comes back as a webhook
`Message::Interactive` with `interactive_type == "button_reply"`.

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :reply_buttons,
  body: "Would you like to confirm your order?",
  action: { buttons: [{ id: "confirm", title: "Confirm" },
                      { id: "cancel",  title: "Cancel" }] }
)
```

| Field | Rules |
| --- | --- |
| `buttons` | 1–**3** entries |
| `buttons[].id` | Required, max **256** characters — echoed back on tap |
| `buttons[].title` | Required, max **20** characters — the visible label |

```ruby
Whatsapp::Messages::Interactive.new(
  to: "+15551234567", type: :reply_buttons, body: "Would you like to confirm your order?",
  action: { buttons: [{ id: "confirm", title: "Confirm" }, { id: "cancel", title: "Cancel" }] }
).serialize
# => { messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567",
#      type: "interactive",
#      interactive: { type: "button",
#        body: { text: "Would you like to confirm your order?" },
#        action: { buttons: [{ type: "reply", reply: { id: "confirm", title: "Confirm" } },
#                            { type: "reply", reply: { id: "cancel",  title: "Cancel" } }] } } }
```

---

## List

One button that expands into up to **10 sections** of up to **10 rows** each. Use it
when three buttons aren't enough — a menu, a time-slot picker, a product list.

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :list_buttons,
  body: "Choose a drink",
  action: {
    button: "Menu",
    sections: [
      { title: "Coffee", rows: [
        { id: "espresso", title: "Espresso", description: "Strong & short" },
        { id: "latte",    title: "Latte",    description: "Milky & mild" },
      ] },
    ],
  }
)
```

| Field | Rules |
| --- | --- |
| `button` | Required, max **20** characters — the label that opens the list |
| `sections` | **1–10** sections |
| `sections[].title` | Required, max **24** characters |
| `sections[].rows` | **1–10** rows |
| `rows[].id` | Required, max **200** characters |
| `rows[].title` | Required, max **24** characters |
| `rows[].description` | Optional, max **72** characters |

```ruby
Whatsapp::Messages::Interactive.new(
  to: "+15551234567", type: :list_buttons, body: "Choose a drink",
  action: { button: "Menu", sections: [
    { title: "Coffee", rows: [{ id: "espresso", title: "Espresso", description: "Strong & short" }] },
  ] }
).serialize
# => { ..., interactive: { type: "list", body: { text: "Choose a drink" },
#      action: { button: "Menu",
#                sections: [{ title: "Coffee",
#                             rows: [{ id: "espresso", title: "Espresso",
#                                      description: "Strong & short" }] }] } } }
```

A tap arrives back as a webhook `Message::Interactive` with
`interactive_type == "list_reply"`.

---

## CTA URL button

Surfaces a link as a tappable button instead of raw text in the body — clearer, and it
sidesteps the link preview.

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :url_button,
  body: "Check out our new arrivals",
  action: { name: "cta_url", display_text: "Shop now", url: "https://example.com/new" }
)
```

| Field | Rules |
| --- | --- |
| `name` | Required, max **20** characters — always `"cta_url"` |
| `display_text` | Required, max **20** characters — the button label |
| `url` | The destination. **Not validated**, not even for presence |

```ruby
Whatsapp::Messages::Interactive.new(
  to: "+15551234567", type: :url_button, body: "Check out our new arrivals",
  action: { name: "cta_url", display_text: "Shop now", url: "https://example.com/new" }
).serialize
# => { ..., interactive: { type: "cta_url", body: { text: "Check out our new arrivals" },
#      action: { name: "cta_url",
#                parameters: { display_text: "Shop now", url: "https://example.com/new" } } } }
```

---

## Media carousel

**2–10** swipeable cards, each with its own header, body, CTA URL, and quick-reply
buttons. `card_index` is assigned automatically from array position — do not pass it.

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :media_carousel,
  body: "Today's picks",
  action: {
    cards: [
      {
        header: { type: "image", link: "https://example.com/1.jpg" },
        body: "Item one",
        action: { name: "cta_url", display_text: "Buy", url: "https://example.com/1" },
        buttons: [{ quick_reply: { id: "q1", title: "Details" } }],
      },
      {
        header: { type: "image", link: "https://example.com/2.jpg" },
        body: "Item two",
        action: { name: "cta_url", display_text: "Buy", url: "https://example.com/2" },
        buttons: [{ quick_reply: { id: "q2", title: "Details" } }],
      },
    ],
  }
)
```

| Field | Rules |
| --- | --- |
| `cards` | **2–10** cards |
| `cards[].header` | Required — same shape as the message header (`link:` only for media) |
| `cards[].body` | Required |
| `cards[].action` | Required — a CTA URL action |
| `cards[].buttons` | Required — array of `{ quick_reply: { id:, title: } }` |

All five card keys are required Ruby keywords; omitting one raises `ArgumentError`,
not a validation error.

> **Two caveats.** The wire value `"carousel"` is flagged in the source as worth
> re-checking against Meta's docs for your API version before relying on it in
> production. And `MediaCarousel::Card::Button::QuickReply` declares `id`/`title`
> length validations but never runs `validate!`, so an over-long or blank
> `id`/`title` serializes silently and is rejected by Meta instead of locally.

---

## Product carousel

**2–10** cards referencing products in your Meta catalog. Like the media carousel,
`card_index` is assigned from array position.

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567",
  type: :product_carousel,
  body: "Recommended for you",
  action: {
    cards: [
      { catalog_id: "123456789", product_retailer_id: "SKU-1" },
      { catalog_id: "123456789", product_retailer_id: "SKU-2" },
    ],
  }
)
```

| Field | Rules |
| --- | --- |
| `cards` | **2–10** cards |
| `cards[].catalog_id` | Required (Ruby keyword) |
| `cards[].product_retailer_id` | Required (Ruby keyword) |

Card contents carry **no validations at all** — a wrong catalog or SKU surfaces
server-side.

> The wire value `"product_list"` carries the same "verify against your API version"
> caveat as the media carousel.

---

## Validation errors

`Interactive` itself validates `type`, `body`, and `action` presence at construction.
The **nested** action rules — button counts, title lengths, section limits — run when
the payload is serialized, which for `send_interactive!` is still before any HTTP
request:

```ruby
Whatsapp::Messages.send_interactive!(
  to: "+15551234567", type: :telepathy, body: "Pick",
  action: { buttons: [{ id: "a", title: "A" }] }
)
# => ActiveModel::ValidationError: Type is not included in the list

Whatsapp::Messages.send_interactive!(
  to: "+15551234567", type: :reply_buttons, body: "Pick",
  action: { buttons: [{ id: "a", title: "A really quite long button label" }] }
)
# => ActiveModel::ValidationError: Title is too long (maximum is 20 characters)
```

---

**Meta docs:**
[CTA URL](https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-cta-url-messages)
· [lists](https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-list-messages)
