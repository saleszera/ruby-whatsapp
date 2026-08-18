# Template Responses

Four endpoints, four response shapes — so four classes rather than one that is mostly
`nil`.

| Method | Returns |
| --- | --- |
| `create`, `create_from_library`, `upsert` | [`Response::Created`](#created) |
| `find` | [`Response::Node`](#node) |
| `list` | [`Response::Collection`](#collection) |
| `update`, `delete` | plain `Boolean` |

## Created

`{id, status, category}` — what you get back from a submission.

```ruby
created = templates.create(name: "order_confirmation", language: "en_US",
                           category: "UTILITY", components: [...])

created.id        # => "1259544702043867"
created.status    # => "PENDING"
created.category  # => "UTILITY"

created.pending?  # => true
created.approved? # => false
created.rejected? # => false
```

A [library template](library.md) usually comes back `APPROVED` immediately; everything
else starts `PENDING` and is reviewed asynchronously.

## Node

The full template object, from `find`.

```ruby
template = templates.find(template_id: "564750795574598")
```

| Accessor | Example |
| --- | --- |
| `id` | `"564750795574598"` |
| `name` | `"order_confirmation"` |
| `status` | `"APPROVED"` |
| `category` | `"UTILITY"` |
| `language` | `"en_US"` |
| `components` | **raw hashes** — see below |
| `parameter_format` | `"POSITIONAL"` |
| `sub_category` | `"ORDER_DETAILS"` |
| `rejected_reason` | `"NONE"` |
| `quality_score` | `#<QualityScore score="GREEN" date=1700000000 reasons=[]>` |
| `previous_category` | `"MARKETING"` |
| `correct_category` | `"UTILITY"` |
| `message_send_ttl_seconds` | `3600` |
| `cta_url_link_tracking_opted_out` | `false` |
| `library_template_name` | `"delivery_update_1"` |

Predicates: `#approved?`, `#rejected?`, `#paused?`, and `#editable?` (true for
`APPROVED`, `REJECTED`, and `PAUSED`).

```ruby
template.status     # => "APPROVED"
template.editable?  # => true
```

> **`#components` stays raw hashes on purpose.** It is not rebuilt into the
> `Component` classes. Those validate a payload being *written*; this is Meta's echo of
> one, carrying fields the write side does not model. Running write-side rules over
> data we did not author would raise on perfectly valid responses. Read it as data;
> build a new `Template` when you want to change something.

```ruby
template.components
# => [{ "type" => "BODY", "text" => "Thank you, {{1}}!",
#       "example" => { "body_text" => [["Pablo"]] } }]
```

## Collection

`{data, paging, summary}` from `list`. It is `Enumerable`, so it behaves like the array
of `Node`s it wraps.

```ruby
page = templates.list(status: %w[APPROVED], limit: 25)

page.map(&:name)                    # => ["order_confirmation", ...]
page.select(&:approved?)            # Enumerable
page.next_cursor                    # => "AFTER" — nil on the last page
page.remaining                      # => 249
```

| Accessor | Holds |
| --- | --- |
| `data` | `Array<Response::Node>` |
| `paging` | `Response::Paging` — `before`, `after` (flattened from `paging.cursors`) |
| `summary` | `Response::Summary` |

`#next_cursor` is `paging&.after`; `#remaining` is `summary&.remaining`.

### Summary

| Accessor | Meaning |
| --- | --- |
| `total_count` | Templates matching the filter |
| `message_template_count` | Templates on the account |
| `message_template_limit` | The account's cap |
| `are_translations_complete` | Boolean |
| `remaining` | `limit - count`, or `nil` when either is missing |

```ruby
page.summary.message_template_count  # => 12
page.summary.message_template_limit  # => 250
page.remaining                       # => 238
```

### Paging

Manual — there is no auto-pagination:

```ruby
page = templates.list(limit: 25)
all  = page.to_a

while (cursor = page.next_cursor)
  page = templates.list(limit: 25, after: cursor)
  all.concat(page.to_a)
end
```

### QualityScore

```ruby
template.quality_score.score    # => "GREEN"  — GREEN | YELLOW | RED | UNKNOWN
template.quality_score.date     # => 1_700_000_000
template.quality_score.reasons  # => []
```

Best-effort schema on `reasons` — Meta publishes no sub-fields for it.

## Booleans

`update` and `delete` return a plain `true`/`false` derived from `{"success": true}`:

```ruby
templates.update(template_id: "564750795574598", category: "MARKETING")  # => true
templates.delete(name: "order_confirmation")                             # => true
```

A non-2xx response raises `Whatsapp::MessageTemplates::TemplateError` instead of
returning `false`, so `false` genuinely means "Meta said no", not "the request failed".

## Statuses

| Status | Meaning |
| --- | --- |
| `PENDING` | Under review |
| `APPROVED` | Sendable |
| `REJECTED` | Refused — see `rejected_reason` |
| `PAUSED` | Temporarily halted for quality |
| `DISABLED` | Permanently disabled; cannot be deleted |
| `IN_APPEAL` | Rejection under appeal |
| `PENDING_DELETION` | Deletion queued |
| `DELETED` | Gone |
| `LIMIT_EXCEEDED` | Account template cap hit |
| `ARCHIVED` | Archived |

`rejected_reason` is one of `NONE`, `ABUSIVE_CONTENT`, `INVALID_FORMAT`,
`PROMOTIONAL`, `TAG_CONTENT_MISMATCH`, `SCAM`.

---

**Meta docs:** <https://developers.facebook.com/docs/graph-api/reference/whats-app-business-hsm/>
