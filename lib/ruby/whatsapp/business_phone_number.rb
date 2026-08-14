# frozen_string_literal: true

module Whatsapp
  # Registers or deregisters a business phone number with Cloud API.
  #
  # This is the switch that makes a phone number usable — or not — with Cloud API in
  # the first place. It is a different concern from {Whatsapp::SubscribedApp}, which
  # turns webhook delivery on and off for a whole WhatsApp Business Account: this
  # module is per phone number and is a prerequisite for messaging itself, not just
  # for notifications. Addresses `phone_id`, like {Whatsapp::Media} and
  # {Whatsapp::Messages}, not `waba_id`.
  # See `lib/ruby/whatsapp/business_phone_number/CLAUDE.md` and
  # `docs/business-phone-number-api.md`.
  # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
  module BusinessPhoneNumber
    class Error < Whatsapp::Error; end
  end
end
