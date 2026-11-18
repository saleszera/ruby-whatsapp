# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    # Reads and updates a business phone number's **conversational components**: the
    # welcome-message switch, the ice breakers (`prompts`) a user can tap the first time they
    # open a chat, and the `/commands` a user sees after typing a slash.
    #
    # Not an exception to the module's `phone_id` rule. {Update} posts to an edge on the phone
    # number (`POST /{phone_id}/conversational_automation`), and {Get} reads a *field* on the
    # phone number node (`GET /{phone_id}?fields=conversational_automation`), so both reuse
    # {BusinessPhoneNumber::Transport}: `edge_path` and `node_path` respectively.
    #
    # Meta documents no `DELETE`: an empty `prompts`/`commands` array and
    # `enable_welcome_message: false` are how settings are switched off. Tapping an ice breaker
    # or sending a command reaches you as an ordinary `text` message webhook
    # ({Whatsapp::Webhook::Message::Text}), so there is nothing extra to deserialize.
    # See `docs/business_phone_number/conversational_automation.md`.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/conversational-automation-api
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/conversational-components
    module ConversationalAutomation
    end
  end
end
