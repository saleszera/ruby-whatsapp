# Contact Messages

Shares a structured, vCard-like contact card the recipient can tap once to save,
instead of pasting a phone number into a text message and hoping they copy it
correctly.

```ruby
Whatsapp::Messages.send_contacts!(
  to: "+15551234567",
  contacts: [{ name: { formatted_name: "Jane Doe", first_name: "Jane", last_name: "Doe" } }]
)
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `contacts` | yes | An array containing **exactly one** contact |

> **Exactly one contact.** The Cloud API currently accepts a single contact per
> message. An empty array raises `Contacts can't be blank`; two or more raises
> `Contacts is too long`. To share several people, send several messages.

Each entry in `contacts` is a hash (or a `Contacts::Contact`) composed of:

| Key | Required | Type |
| --- | --- | --- |
| `name` | yes | `Name` |
| `phones` | no | `Array<Phone>` |
| `emails` | no | `Array<Email>` |
| `addresses` | no | `Array<Address>` |
| `urls` | no | `Array<Url>` |
| `org` | no | `Org` |
| `birthday` | no | `"YYYY-MM-DD"` string |

### Sub-object fields

| Object | Fields | Notes |
| --- | --- | --- |
| `Name` | `formatted_name` (**required**), `first_name`, `last_name`, `middle_name`, `prefix`, `suffix` | |
| `Phone` | `phone` (**required**), `type`, `wa_id` | `type`: `CELL` `MAIN` `IPHONE` `HOME` `WORK` `OTHER` |
| `Email` | `email` (**required**), `type` | `type`: `HOME` `WORK` `OTHER` |
| `Address` | `street`, `city`, `state`, `zip`, `country`, `country_code`, `type` | all optional; `type`: `HOME` `WORK` `OTHER` |
| `Url` | `url` (**required**), `type` | `type`: `WEBSITE` `HOMEPAGE` `WORK` `HOME` `OTHER` |
| `Org` | `company`, `department`, `title` | all optional, no validation |

## A full example

```ruby
Whatsapp::Messages.send_contacts!(
  to: "+15551234567",
  contacts: [
    {
      name: { formatted_name: "Jane Doe", first_name: "Jane", last_name: "Doe" },
      phones: [{ phone: "+15550001111", type: "WORK" }],
      emails: [{ email: "jane@example.com", type: "WORK" }],
      addresses: [{ street: "1 Hacker Way", city: "Menlo Park", state: "CA",
                    zip: "94025", country: "United States", country_code: "us", type: "WORK" }],
      urls: [{ url: "https://example.com", type: "WEBSITE" }],
      org: { company: "Acme Inc.", department: "Support", title: "Lead" },
      birthday: "1990-05-12",
    },
  ]
)
```

## Serialized payload

```ruby
Whatsapp::Messages::Contacts.new(
  to: "+15551234567",
  contacts: [
    {
      name: { formatted_name: "Jane Doe", first_name: "Jane", last_name: "Doe" },
      phones: [{ phone: "+15550001111", type: "WORK" }],
      emails: [{ email: "jane@example.com", type: "WORK" }],
      org: { company: "Acme Inc." },
      birthday: "1990-05-12",
    },
  ]
).serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "contacts",
#   contacts: [{
#     name: { formatted_name: "Jane Doe", first_name: "Jane", last_name: "Doe" },
#     phones: [{ phone: "+15550001111", type: "WORK" }],
#     emails: [{ email: "jane@example.com", type: "WORK" }],
#     org: { company: "Acme Inc." },
#     birthday: "1990-05-12"
#   }]
# }
```

Every sub-object compacts its own hash, and `Contact` omits `phones`/`emails`/
`addresses`/`urls` entirely when they're empty — so a minimal card is just `name`.

> **Known gap.** `Contacts::Name` validates only the presence of `formatted_name`, but
> live testing returns `(#131009) ContactName should have atleast one optional value be
> set along with formatted Name`. Meta requires at least one *additional* name field
> (e.g. `first_name`) alongside `formatted_name`; this class doesn't yet enforce it, so
> a name-only card passes local validation and is rejected server-side. Always set a
> second name field.

## Validation errors

```ruby
Whatsapp::Messages.send_contacts!(to: "+15551234567", contacts: [])
# => ActiveModel::ValidationError: Contacts can't be blank

Whatsapp::Messages.send_contacts!(to: "+15551234567", contacts: [contact_a, contact_b])
# => ActiveModel::ValidationError: Contacts is too long (maximum is 1 character)

Whatsapp::Messages.send_contacts!(to: "+15551234567", contacts: [{ name: { first_name: "Jane" } }])
# => ArgumentError: missing keyword: :formatted_name

Whatsapp::Messages.send_contacts!(to: "+15551234567", contacts: [{ name: { formatted_name: "" } }])
# => ActiveModel::ValidationError: Formatted name can't be blank

Whatsapp::Messages.send_contacts!(
  to: "+15551234567",
  contacts: [{ name: { formatted_name: "Jane Doe" }, phones: [{ phone: "+1", type: "MOBILE" }] }]
)
# => ActiveModel::ValidationError: Type is not included in the list
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/contacts-messages>
