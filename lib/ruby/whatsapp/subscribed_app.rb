# frozen_string_literal: true

module Whatsapp
  # Subscribes or unsubscribes this app from a WhatsApp Business Account's webhook
  # notifications, and lists which apps are currently subscribed.
  #
  # This is what turns webhook delivery on and off in the first place — the opposite
  # concern from {Whatsapp::Webhook}, which only deserializes notifications once Meta
  # is already sending them. Addresses `waba_id`, not `phone_id`, like
  # {Whatsapp::MessageTemplates}. See `lib/ruby/whatsapp/subscribed_app/CLAUDE.md`.
  # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api
  module SubscribedApp
    class Error < Whatsapp::Error; end
  end
end
