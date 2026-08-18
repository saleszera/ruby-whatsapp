# frozen_string_literal: true

module Whatsapp
  # Onboards and deboards a business phone number with Cloud API: requesting and
  # verifying a phone number's verification code, then registering or deregistering it.
  #
  # This is the switch that makes a phone number usable — or not — with Cloud API in
  # the first place. It is a different concern from {Whatsapp::SubscribedApp}, which
  # turns webhook delivery on and off for a whole WhatsApp Business Account: this
  # module is per phone number and is a prerequisite for messaging itself, not just
  # for notifications. Addresses `phone_id`, like {Whatsapp::Media} and
  # {Whatsapp::Messages}, not `waba_id`.
  #
  # The full flow, in order: {RequestCode} -> {VerifyCode} -> {Register}, with
  # {Deregister} as the reverse switch.
  # See `lib/ruby/whatsapp/business_phone_number/CLAUDE.md` and
  # `docs/business_phone_number/README.md`.
  # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
  module BusinessPhoneNumber
    class Error < Whatsapp::Error; end
  end
end
