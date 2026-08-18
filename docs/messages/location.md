# Location Messages

Shares a fixed latitude/longitude pin — a shop, a pickup point, a venue. The inverse
direction (asking the *user* where they are) is
[Location Request](location_request.md).

```ruby
Whatsapp::Messages.send_location!(
  to: "+15551234567",
  latitude: 37.4847,
  longitude: -122.1477,
  name: "Meta HQ"
)
```

## Fields

| Field | Required | Rules |
| --- | --- | --- |
| `to` | yes | The recipient's phone number |
| `latitude` | yes | Numeric |
| `longitude` | yes | Numeric |
| `name` | no | Label shown above the pin |
| `address` | no | Street address shown under the name |

Both coordinates are validated with `numericality`, so a string that doesn't parse as
a number is rejected locally. `name` and `address` are free text — WhatsApp renders
them as the pin's caption; without them the recipient sees bare coordinates.

## Serialized payload

```ruby
Whatsapp::Messages::Location.new(
  to: "+15551234567", latitude: 37.4847, longitude: -122.1477, name: "Meta HQ"
).serialize
# => {
#   messaging_product: "whatsapp", recipient_type: "individual", to: "+15551234567", type: "location",
#   location: { latitude: 37.4847, longitude: -122.1477, name: "Meta HQ" }
# }
```

## Validation errors

```ruby
Whatsapp::Messages.send_location!(to: "+15551234567", latitude: "here", longitude: -122.1477)
# => ActiveModel::ValidationError: Latitude is not a number
```

---

**Meta docs:** <https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/location-messages>
