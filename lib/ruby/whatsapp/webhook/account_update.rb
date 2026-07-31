# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Partner-led verification, authentication rates, primary location, policy
    # violations, offboarding, reconnection, or deletion of a WhatsApp Business Account.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class AccountUpdate
      # @!attribute [rw] phone_number
      #   @return [String, nil]
      attr_accessor :phone_number

      # @!attribute [rw] event
      #   @return [String, nil] e.g. `"VERIFIED_ACCOUNT"`, `"DISABLED_UPDATE"`, `"PARTNER_APP_INSTALLED"`.
      attr_accessor :event

      # @!attribute [rw] ban_info
      #   @return [BanInfo, nil]
      attr_accessor :ban_info

      def initialize(phone_number:, event:, ban_info: nil)
        @phone_number = phone_number
        @event = event
        @ban_info = ban_info
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [AccountUpdate]
        def deserialize(data)
          data ||= {}

          new(
            phone_number: data["phone_number"],
            event: data["event"],
            ban_info: data["ban_info"] ? BanInfo.deserialize(data["ban_info"]) : nil
          )
        end
      end
    end
  end
end
