# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Reads and updates the WhatsApp Business Account node itself — the account a
    # business phone number belongs to, as opposed to the number's own onboarding
    # state that the rest of this module drives.
    #
    # This is the one part of {Whatsapp::BusinessPhoneNumber} that addresses `waba_id`
    # rather than `phone_id`, so it carries its own {Transport} and cannot share
    # {BusinessPhoneNumber::Transport}. It is also the only endpoint pair here that
    # touches the account rather than the number: {Get} reads review, verification, and
    # ownership state; {Update} renames the account or moves its timezone.
    #
    # Distinct from {Whatsapp::SubscribedApp}, which addresses the same `waba_id` but
    # only toggles webhook delivery, and from {Whatsapp::MessageTemplates}, which
    # manages the templates hanging off that account.
    # See `docs/business_phone_number/account.md`.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/whatsapp-business-account-api
    module Account
    end
  end
end
