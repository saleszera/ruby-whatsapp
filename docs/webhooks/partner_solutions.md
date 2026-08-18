# `partner_solutions`

Lifecycle events for a Tech Provider "solution" — the packaged onboarding a partner
offers to its own customers.

`Whatsapp::Webhook::PartnerSolutions` · confidence: **low**

## Payload

```json
{ "field": "partner_solutions", "value": { "solution_id": "sol.1", "event": "DISCONNECTED" } }
```

## Accessors

| Accessor | Meaning |
| --- | --- |
| `solution_id` | The solution's ID |
| `event` | e.g. `CONNECTED`, `DISCONNECTED` |

## Handling it

```ruby
when "partner_solutions"
  Solution.find_by(meta_id: change.value.solution_id)&.update!(state: change.value.event)
```

Relevant only if you operate as a Tech Provider. Most integrations never see it.

> **Best-effort schema, low confidence.** Validate against a real payload before
> depending on it in production.

---

**Meta docs:** https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
