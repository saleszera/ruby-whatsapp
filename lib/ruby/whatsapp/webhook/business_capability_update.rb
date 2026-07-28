# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Messaging limits, phone number limits, and capability changes for a
    # WhatsApp Business Account.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class BusinessCapabilityUpdate
      # @!attribute [rw] max_daily_conversation_per_phone
      #   @return [Integer, nil]
      attr_accessor :max_daily_conversation_per_phone

      # @!attribute [rw] max_phone_numbers_per_business
      #   @return [Integer, nil]
      attr_accessor :max_phone_numbers_per_business

      def initialize(max_daily_conversation_per_phone:, max_phone_numbers_per_business:)
        @max_daily_conversation_per_phone = max_daily_conversation_per_phone
        @max_phone_numbers_per_business = max_phone_numbers_per_business
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [BusinessCapabilityUpdate]
        def deserialize(data)
          data ||= {}

          new(
            max_daily_conversation_per_phone: data["max_daily_conversation_per_phone"],
            max_phone_numbers_per_business: data["max_phone_numbers_per_business"]
          )
        end
      end
    end
  end
end
