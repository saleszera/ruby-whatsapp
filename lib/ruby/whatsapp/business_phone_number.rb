# frozen_string_literal: true

module Whatsapp
  # Onboards and deboards a business phone number with Cloud API: requesting and
  # verifying a phone number's verification code, then registering or deregistering it.
  #
  # This is the switch that makes a phone number usable — or not — with Cloud API in
  # the first place. It is a different concern from {Whatsapp::SubscribedApp}, which
  # turns webhook delivery on and off for a whole WhatsApp Business Account: this
  # module is per phone number and is a prerequisite for messaging itself, not just
  # for notifications. The onboarding actions address `phone_id`, like
  # {Whatsapp::Media} and {Whatsapp::Messages}.
  #
  # The full flow, in order: {RequestCode} -> {VerifyCode} -> {Register}, with
  # {Deregister} as the reverse switch.
  #
  # {Profile} reads and updates the public card a WhatsApp user sees before they reply.
  # It addresses `phone_id` like the onboarding actions above, so it shares their transport.
  #
  # {Account} is the one exception to the `phone_id` rule: it reads and updates the
  # WhatsApp Business Account a number belongs to, so it addresses `waba_id` and
  # carries its own transport.
  # See `lib/ruby/whatsapp/business_phone_number/CLAUDE.md`,
  # `docs/business_phone_number/README.md`, and `docs/business_phone_number/profile.md`.
  # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/registration
  module BusinessPhoneNumber
    class Error < Whatsapp::Error; end
  end
end
