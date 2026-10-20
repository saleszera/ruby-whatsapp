# frozen_string_literal: true

module Whatsapp
  # Lists and creates a WhatsApp Business Account's campaign schedules: an approved
  # template sent to an audience at a set time.
  #
  # Schedules *send* templates that already exist; {Whatsapp::MessageTemplates} is what
  # creates and manages the templates themselves. Addresses `waba_id`, not `phone_id`,
  # like {Whatsapp::MessageTemplates} and {Whatsapp::SubscribedApp}.
  # See `lib/ruby/whatsapp/schedule/CLAUDE.md` and `docs/schedule/README.md`.
  # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api
  module Schedule
    class Error < Whatsapp::Error; end
  end
end
