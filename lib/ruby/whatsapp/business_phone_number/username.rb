# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Reads, claims, and deletes the **business username** on a phone number — the
    # searchable `@name` a WhatsApp user can find you by, as opposed to the display name,
    # which they cannot search for.
    #
    # Like {Profile}, and unlike {Account}, this is not an exception to the module's
    # `phone_id` rule: Meta exposes both edges on the phone number itself
    # (`GET`/`POST`/`DELETE /{phone_id}/username` and
    # `GET /{phone_id}/username_suggestions`), so all four actions reuse
    # {BusinessPhoneNumber::Transport} unchanged. It is the first sub-namespace here to
    # address two edges, which is exactly why `edge_path` takes the edge as an argument.
    #
    # A username is 1:1 with a phone number across all of WhatsApp — no two numbers,
    # consumer or business, can hold the same one. Adopting one does **not** hide your
    # phone number in the app; it is a discovery feature, not a privacy one, which is the
    # opposite of what a *user* username does. The asynchronous counterpart is the
    # `business_username_updates` webhook (see `docs/webhooks/business_username_updates.md`),
    # which is also the only place a `"deleted"` status ever appears.
    # See `docs/business_phone_number/username.md`.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
    module Username
    end
  end
end
