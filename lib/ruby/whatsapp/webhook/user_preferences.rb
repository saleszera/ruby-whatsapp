# frozen_string_literal: true

module Whatsapp
  module Webhook
    # User marketing message preference changes (e.g. a customer opting out of
    # marketing messages).
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class UserPreferences
      # @!attribute [rw] wa_id
      #   @return [String, nil]
      attr_accessor :wa_id

      # @!attribute [rw] detail
      #   @return [String, nil]
      attr_accessor :detail

      # @!attribute [rw] value
      #   @return [String, nil] e.g. `"stop"`, `"resume"`.
      attr_accessor :value

      # @!attribute [rw] timestamp
      #   @return [String, nil]
      attr_accessor :timestamp

      def initialize(wa_id:, detail:, value:, timestamp:)
        @wa_id = wa_id
        @detail = detail
        @value = value
        @timestamp = timestamp
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [UserPreferences]
        def deserialize(data)
          data ||= {}

          new(wa_id: data["wa_id"], detail: data["detail"], value: data["value"], timestamp: data["timestamp"])
        end
      end
    end
  end
end
