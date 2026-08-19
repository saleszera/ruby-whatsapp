# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Reads and updates a business phone number's **business profile** — the public card a
    # WhatsApp user sees before they reply: the about line, description, address, email,
    # websites, industry vertical, and profile picture.
    #
    # Unlike {Account}, this is not an exception to the module's `phone_id` rule: Meta exposes
    # the profile as an edge on the phone number itself
    # (`GET`/`POST /{phone_id}/whatsapp_business_profile`), so {Get} and {Update} address the
    # same ID the onboarding actions do and reuse {BusinessPhoneNumber::Transport} unchanged.
    #
    # Distinct from {Account}, which describes the *account* a number belongs to rather than
    # how that number presents itself, and from {Whatsapp::Messages}, which is what actually
    # reaches a user once the profile is set.
    # See `docs/business_phone_number/profile.md`.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/whatsapp-business-profile-api
    module Profile
    end
  end
end
