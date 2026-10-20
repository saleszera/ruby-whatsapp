# Business usernames

A business username is the searchable `@name` a WhatsApp user can find you by. It is the
business half of Meta's usernames rollout — the user half is what makes
[`recipient:`](../messages/README.md#addressing-to-recipient-or-both) necessary when
sending.

Two things it is **not**: it does not hide your business phone number in the app (unlike
a *user* username, which hides theirs), and it does not replace your display name. When
you have both, the display name shows first.

```ruby
Whatsapp::BusinessPhoneNumber::Username::Get.call
Whatsapp::BusinessPhoneNumber::Username::Claim.call(username: "jaspersmarket")
Whatsapp::BusinessPhoneNumber::Username::Suggest.call
Whatsapp::BusinessPhoneNumber::Username::Delete.call
```

| Method | Request | Returns |
| --- | --- | --- |
| `Get.call` | `GET /{phone_id}/username` | `Username::Details` |
| `Claim.call(username:, transfer_action:)` | `POST /{phone_id}/username` | `Username::Details` |
| `Delete.call` | `DELETE /{phone_id}/username` | `Response` |
| `Suggest.call` | `GET /{phone_id}/username_suggestions` | `Username::Suggestions` |

## Reading the current username

```ruby
details = Whatsapp::BusinessPhoneNumber::Username::Get.call

details.username   # => "jaspersmarket", or nil if the number has none
details.status     # => "approved" | "reserved"
details.approved?  # => true once it is visible to WhatsApp users
details.reserved?  # => held for you, but not visible yet
```

`status` stays a raw String and is never validated on the way in, so a value Meta adds
later still round-trips. Compare against `Details::Statuses::ALL` (`%w[approved reserved]`).

## The lifecycle

```
Suggest  ──▶  Claim  ──▶  reserved  ──▶  approved
(what Meta    (ask for               (Meta makes the feature
 reserved      one)                   generally available)
 for you)
```

`reserved` means the name is yours but not yet shown to users. It becomes `approved` on
its own — you do not claim it twice. Either poll `Get`, or subscribe to the
[`business_username_updates`](../webhooks/business_username_updates.md) webhook, which
is the asynchronous counterpart to everything on this page.

## Claiming one

```ruby
details = Whatsapp::BusinessPhoneNumber::Username::Claim.call(username: "jaspersmarket")
details.status  # => "reserved"
```

`Claim` answers with a status only — `details.username` is `nil`, because you already
hold the name you passed in.

Starting with names Meta reserved for you gives a higher chance of approval:

```ruby
suggestions = Whatsapp::BusinessPhoneNumber::Username::Suggest.call

suggestions.to_a    # => ["jaspersmarket", "jaspers_market"]
suggestions.first   # => "jaspersmarket" — it's Enumerable

Whatsapp::BusinessPhoneNumber::Username::Claim.call(username: suggestions.first)
```

### Format rules

Checked locally, before any request — the edge is rate limited, so a name that was never
going to be accepted should not cost you an attempt:

| Rule | Rejected example |
| --- | --- |
| Only `a-z`, `0-9`, `.` and `_` | `jaspers-market`, `jasperś` |
| 3–35 characters | `ab`, `a` × 36 |
| At least one letter | `12345` |
| Must not start or end with `.` | `.jaspers`, `jaspers.` |
| No two consecutive `.` | `jaspers..market` |
| Must not start with `www` | `www.jaspers` |
| Must not end with a domain suffix | `jaspers.com`, `jaspers.html` |

Each failure raises `ActiveModel::ValidationError` naming the rule.

Three things worth knowing about how these are applied:

- **Mixed case is downcased, not rejected.** Meta compares usernames case-insensitively,
  so `"JaspersMarket"` is sent as `"jaspersmarket"`. Refusing a name Meta would have
  accepted is the failure mode this gem avoids.
- **`.` and `_` are significant.** `myid`, `my.id`, and `my_id` are three different names.
- **`www` is read literally**, so `wwwidgets` is rejected too. Meta writes the rule as a
  bare prefix; a reversible local rejection beats a wasted request.

> The domain-suffix list is **`.com .org .net .int .edu .gov .mil .us .in .html`** —
> and Meta's own list ends in "and so on", so it cannot be complete. A suffix outside it
> reaches the API and comes back as error `100`.

### Moving a username between your own numbers

If another phone number *in the same portfolio* holds the name, `Claim` fails with
`147005`. Resend with a forced transfer:

```ruby
Whatsapp::BusinessPhoneNumber::Username::Claim.call(
  username: "jaspersmarket",
  transfer_action: :force_transfer
)
```

> **This takes the name off the other number.** There is deliberately no automatic
> retry — a destructive step stays an explicit one.

## Deleting one

```ruby
Whatsapp::BusinessPhoneNumber::Username::Delete.call.success  # => true
```

Note this reports `success`, not a status: a delete arrives back through the
[webhook](../webhooks/business_username_updates.md) as `status: "deleted"`, which is the
only place that value ever appears — `Details::Statuses::ALL` deliberately omits it.

## Errors

| Code | Meaning and remedy |
| --- | --- |
| `10` | The token's system user needs Full control, or Partial access for Phone numbers, on the WABA |
| `33` | Invalid phone number ID, deleted WABA, or the app lacks `whatsapp_business_management` |
| `100` | The username format is invalid — including a domain suffix outside the list above |
| `147001` | Already claimed, or failed Meta's internal checks. Try another |
| `147002` | The portfolio's [messaging limit](https://developers.facebook.com/documentation/business-messaging/whatsapp/messaging-limits) is too low |
| `147003` | Link the number to the Facebook Page already using this name |
| `147004` | Link the number to the Instagram account already using this name |
| `147005` | Another of your numbers holds it — resend with `transfer_action: "force_transfer"` |
| `133010` | The number must be [registered](README.md) for API use first |

All arrive as `Whatsapp::BusinessPhoneNumber::Error` with Meta's message attached.

## Targeting a different number

```ruby
Whatsapp::BusinessPhoneNumber::Username::Get.call(client: Whatsapp::Client.new(phone_id: "OTHER_ID"))
```

---

**See also:** [`business_username_updates` webhook](../webhooks/business_username_updates.md) ·
[Sending to a BSUID](../messages/README.md#business-scoped-user-ids-bsuid)

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
