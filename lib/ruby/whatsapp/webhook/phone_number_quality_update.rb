# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Business phone throughput/quality level changes.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class PhoneNumberQualityUpdate
      # @!attribute [rw] display_phone_number
      #   @return [String, nil]
      attr_accessor :display_phone_number

      # @!attribute [rw] event
      #   @return [String, nil] e.g. `"UPGRADE"`, `"DOWNGRADE"`.
      attr_accessor :event

      # @!attribute [rw] current_limit
      #   @return [String, nil] e.g. `"TIER_50"`, `"TIER_250"`, `"TIER_1K"`.
      attr_accessor :current_limit

      def initialize(display_phone_number:, event:, current_limit:)
        @display_phone_number = display_phone_number
        @event = event
        @current_limit = current_limit
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [PhoneNumberQualityUpdate]
        def deserialize(data)
          data ||= {}

          new(
            display_phone_number: data["display_phone_number"],
            event: data["event"],
            current_limit: data["current_limit"]
          )
        end
      end
    end
  end
end
