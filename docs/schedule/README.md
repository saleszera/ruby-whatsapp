# Scheduling Campaigns

A **campaign schedule** sends an approved [template](../message_templates/README.md) to an
audience at a time you choose. `Whatsapp::Schedule` wraps the `schedules` edge, which
lists an account's schedules and creates new ones.

> **Schedules send templates; they don't create them.** The template behind `hsm_id`
> must already exist and be approved. Create and manage it with
> [`Whatsapp::MessageTemplates`](../message_templates/README.md).

Addresses your **WhatsApp Business Account** (`waba_id`, not `phone_id`), the same as
[template management](../message_templates/README.md) and
[subscribed apps](../subscribed_app/README.md).

```ruby
Whatsapp.configure do |config|
  config.api_key = ENV.fetch("WHATSAPP_API_KEY")
  config.waba_id = ENV.fetch("WHATSAPP_WABA_ID")
end

Whatsapp::Schedule::Create.call(
  hsm_id: "1234567890", audience_id: "2345678901", waba_cs_id: "3456789012",
  name: "Black Friday", description: "Black Friday promo to VIP customers",
  delivery_time: Time.now.to_i + 3600
).id                                                # => "9876543210"

Whatsapp::Schedule::List.call.map(&:name)           # => ["Black Friday"]
```

| Method | Request | Returns |
| --- | --- | --- |
| `List.call(client:, fields:, limit:, after:, before:)` | `GET /{waba_id}/schedules` | `Response::Collection` |
| `Create.call(hsm_id:, audience_id:, waba_cs_id:, name:, description:, delivery_time:, client:)` | `POST /{waba_id}/schedules` | `Response::Created` |

## Creating

Every field is required:

| Field | Type | Meaning |
| --- | --- | --- |
| `hsm_id` | String | The approved template to send |
| `audience_id` | String | The audience to send it to |
| `waba_cs_id` | String | Meta: "WABA customer status ID (phone number)" |
| `name` | String | The schedule's name |
| `description` | String | The schedule's description |
| `delivery_time` | Integer | When to send, as a Unix timestamp |

The examples below share this hash:

```ruby
attrs = {
  hsm_id: "1234567890", audience_id: "2345678901", waba_cs_id: "3456789012",
  name: "Black Friday", description: "Black Friday promo to VIP customers",
  delivery_time: 1_764_000_000,
}
```

`delivery_time` must be an integer. For a `Time`, pass `time.to_i`:

```ruby
Whatsapp::Schedule::Create.call(**attrs, delivery_time: Time.utc(2026, 11, 27, 9).to_i)
```

All six are checked before the request, so a missing one costs nothing:

```ruby
Whatsapp::Schedule::Create.call(**attrs, name: "")
# => ActiveModel::ValidationError: Validation failed: Name can't be blank

Whatsapp::Schedule::Create.call(**attrs, delivery_time: 1_764_000_000.5)
# => ActiveModel::ValidationError: Validation failed: Delivery time must be an integer
```

Nothing beyond that is checked. Meta publishes no length limits and no rule that
`delivery_time` must be in the future; anything it rejects comes back as a
`Whatsapp::Schedule::Error`.

> `waba_cs_id` is passed through exactly as given. Meta's description doesn't say
> whether it means a phone number ID or the number itself.

To inspect the payload without sending it, build the object yourself:

```ruby
Whatsapp::Schedule::Create.new(**attrs).serialize
# => { hsm_id: "1234567890", audience_id: "2345678901", waba_cs_id: "3456789012",
#      name: "Black Friday", description: "Black Friday promo to VIP customers",
#      delivery_time: 1764000000 }
```

## Listing

```ruby
schedules = Whatsapp::Schedule::List.call

schedules.map(&:name)              # Collection is Enumerable
schedules.first.delivery_time      # => 1764000000
schedules.first.status             # => "SCHEDULED"
schedules.first.id                 # => nil (see below)
```

### Ask for `id` explicitly

**Meta's default fields leave out `id`.** The defaults are `name`, `description`,
`delivery_time`, and `status`. Request `id` with `fields:`, either as an Array or a
comma-joined String:

```ruby
Whatsapp::Schedule::List.call(fields: Whatsapp::Schedule::List::Fields::ALL)
Whatsapp::Schedule::List.call(fields: %w[id name status])
Whatsapp::Schedule::List.call(fields: "id,name,status")
```

`List::Fields::ALL` is a convenience, not a whitelist. A field Meta adds later works
without a gem release.

### Paging

`limit:` sets the page size (Meta accepts 1–100). `after:` and `before:` take cursors.
Paging is exposed rather than followed automatically, so fetching every page is your
choice:

```ruby
page = Whatsapp::Schedule::List.call(limit: 50)

while page.next_cursor
  page = Whatsapp::Schedule::List.call(limit: 50, after: page.next_cursor)
end
```

`Collection#paging` exposes both cursors (`paging.before`, `paging.after`). It is the
same Graph API paging object [template listing](../message_templates/README.md) returns.

### Statuses

| Status | Predicate |
| --- | --- |
| `SCHEDULED` | `scheduled?` |
| `SENDING` | `sending?` |
| `COMPLETED` | `completed?` |
| `FAILED` | `failed?` |

```ruby
Whatsapp::Schedule::List.call.select(&:failed?).map(&:name)
schedule.status == Whatsapp::Schedule::Statuses::SCHEDULED
```

`status` is the raw string Meta sent and is never validated, so a status Meta adds later
still comes through. Every predicate just answers `false` for it.

## Response shapes

| Class | Holds | From |
| --- | --- | --- |
| `Response::Collection` | `data: [Node]`, `paging`, `next_cursor`, `Enumerable` | `List` |
| `Response::Node` | `id`, `name`, `description`, `delivery_time`, `status` | each element of `List` |
| `Response::Created` | `id` | `Create` |

Every attribute tolerates being absent, since Meta returns only the fields you asked for.

## Errors

```ruby
Whatsapp::Schedule::List.call
# => Whatsapp::Schedule::Error: waba_id is required for schedules;
#    set it via Whatsapp.configure or Client.new(waba_id:)

# non-2xx response
# => Whatsapp::Schedule::Error: Failed to create schedule: 403 Forbidden - {...}
```

Every API failure raises `Whatsapp::Schedule::Error`, never the generic
`Whatsapp::RequestError`. Local validation raises `ActiveModel::ValidationError` before
any request. See [../errors.md](../errors.md).

## Targeting a different account

```ruby
Whatsapp::Schedule::List.call(client: Whatsapp::Client.new(waba_id: "OTHER_WABA_ID"))
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api>
