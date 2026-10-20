# Contact book

Meta keeps a **contact book** for your business portfolio: the phone numbers and BSUIDs
of users you have interacted with. Its purpose is thread continuity — once a user adopts
a username, Meta will keep putting their phone number in your webhooks if they are in
your contact book, instead of leaving you with only their
[BSUID](../webhooks/messages.md#business-scoped-user-ids-bsuid).

The store itself is hosted by Meta and needs no integration work; entries appear on their
own as you exchange messages or calls, and when a user taps a `REQUEST_CONTACT_INFO`
button (which arrives as a [`contacts` message](../webhooks/messages.md#contacts) with
`origin == "contact_request"`). This page covers the one operation Meta exposes on it:
removing an entry.

| Method | Request | Returns |
| --- | --- | --- |
| `ContactBook::Delete.call(bsuid:)` | `DELETE /{phone_id}/contact_book` | `ContactBook::Deletion` |

## Deleting an entry

```ruby
result = Whatsapp::BusinessPhoneNumber::ContactBook::Delete.call(bsuid: "US.13491208655302741918")

result.success  # => true  — the request was processed
result.deleted  # => true  — an entry existed and is gone
```

The two booleans are independent, which is why this returns its own class rather than the
shared `Response`:

| `success` | `deleted` | Meaning |
| --- | --- | --- |
| `true` | `true` | An entry existed and was removed |
| `true` | `false` | The request was fine; there was nothing stored for that BSUID |
| `false` | — | The request was not processed |

So `deleted == false` is **not** a failure. Check `success` for that, or rescue
`Whatsapp::BusinessPhoneNumber::Error`.

## What it affects

> **The edge is on one phone number; the effect is portfolio-wide.** Contact books are
> scoped to the business portfolio, so deleting an entry removes that user's phone number
> from webhooks for **every** business phone number in the portfolio — not just the one
> you addressed.

And the consequence to expect: after a deletion, `wa_id`/`from` may start being omitted
from your webhooks for that user, leaving their BSUID as the only identifier. That is the
feature working, not a bug — but code that keys off `wa_id` will notice.

The phone number can come back, without a new deletion, if the user messages or calls you
again (or you them) within the 30-day window Meta caches, since that recreates the entry.

## Rules

- **Standard BSUIDs only.** Parent BSUIDs are not supported. Since this release hands you
  `user_id` and `parent_user_id` side by side on half a dozen webhook classes, the mix-up
  is easy, so it is caught locally:

  ```ruby
  Whatsapp::BusinessPhoneNumber::ContactBook::Delete.call(bsuid: "US.ENT.11815799212886844830")
  # => ActiveModel::ValidationError: Bsuid looks like a parent BSUID;
  #    the contact book accepts standard BSUIDs only
  ```

  Detected by segment count rather than by matching `ENT`, which would bet that `ENT` is
  the only marker Meta will ever use.

- **Same portfolio.** The BSUID must belong to the same portfolio as the phone number.
  That is account state the gem cannot see, so it is left to the API — a mismatch comes
  back as `Whatsapp::BusinessPhoneNumber::Error`.

## Disabling the feature entirely

The contact book can be turned off in **Meta Business Suite → Business settings →
Business info**. Disabling it stops all storage and deletes everything already stored;
re-enabling starts fresh, with no way to restore the old contents. There is no API for
this, so it is not wrapped.

## Not wrapped

Meta documents only the delete on this edge. A future read or write belongs in this same
namespace.

---

**See also:** [Business usernames](username.md) ·
[BSUIDs in webhooks](../webhooks/messages.md#business-scoped-user-ids-bsuid)

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
